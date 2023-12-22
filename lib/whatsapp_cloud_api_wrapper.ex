defmodule WhatsappCloudApiWrapper do
  @moduledoc """
  Documentation for `WhatsappCloudApiWrapper`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> WhatsappCloudApiWrapper.hello()
      :world

  """

  # Todo: comment it. Use docs.

  @default_headers %{
    "Content-Type": "application/json",
    "Accept-Language": "en_US",
    Accept: "application/json"
  }

  defp get_base_url(%{"version" => version} = params) do
    SENDER_PHONE_NUMBER = Application.get_env(:whatsapp_cloud_api_wrapper, "META_WA_SENDER_PHONE_NUMBER_ID")
    "https://graph.facebook.com/#{version}/#{SENDER_PHONE_NUMBER}/messages"
  end

  defp get_base_url do
    SENDER_PHONE_NUMBER = Application.get_env(:whatsapp_cloud_api_wrapper, "META_WA_SENDER_PHONE_NUMBER_ID")
    "https://graph.facebook.com/v18.0/#{SENDER_PHONE_NUMBER}/messages"
  end

  defp blank_default(val, default_val) do
    if val == nil, do: default_val, else: val
  end

  defp validate_and_format_interactive_msg_buttons_list(btn_list) do
    is_valid = true
    error_msg = nil
    formatted_list = []

    Enum.each(btn_list, fn btn ->
      %{"title" => title, "id" => id} = btn

      if !title || length(title) > 20 || !id || length(id) > 256 do
        is_valid = false

        if !title do
          error_msg = "title is missing."
        end

        if length(title) > 20 do
          error_msg = "The button title must be between 1 and 20 characters long."
        end

        if !id do
          error_msg = "id is missing"
        end

        if length(id) > 256 do
          error_msg = "The button id must be between 1 and 256 characters long."
        end
      end

      if is_valid do
        List.insert_at(formatted_list, 0, %{
          "type" => "reply",
          "reply" => %{"title" => title, "id" => id}
        })
      end
    end)

    if is_valid do
      {:ok, formatted_list}
    else
      {:error, error_msg}
    end
  end

  defp validate_and_format_interactive_msg_sections_list(section_list) do
    is_valid = true
    error_msg = nil

    Enum.each(section_list, fn %{"title" => section_title, "rows" => rows} = section ->
      if !section_title do
        error_msg = "title of a section is required in list of radio buttons"
      end

      if length(rows) > 10 do
        error_msg = "The number of items in the rows must be equal or less than 10."
      end

      Enum.each(rows, fn %{"id" => id, "title" => title, "description" => description} ->
        if !title || !id || !description || length(title) > 24 || length(id) > 200 || !description ||
             length(description) > 72 do
          is_valid = false

          if !title do
            error_msg = "row title is missing."
          end

          if !id do
            error_msg = "row id is missing"
          end

          if !description do
            error_msg = "row description is missing"
          end

          if length(title) > 24 do
            error_msg = "The row title must be between 1 and 24 characters long."
          end

          if length(id) > 256 do
            error_msg = "The row id must be between 1 and 200 characters long."
          end

          if length(description) > 72 do
            error_msg = "The row description must be between 1 and 72 characters long."
          end
        end
      end)
    end)

    if is_valid do
      {:ok, section_list}
    else
      {:error, error_msg}
    end
  end

  # defp upload_media(%{file_path, file_name} = params) do
  #   # todo
  # end

  def mark_msg_as_read(msg_id) do
    if msg_id != nil do
      Req.post!(
        url: get_base_url(),
        headers: @default_headers,
        json: %{
          "messaging_product" => "whatsapp",
          "status" => "read",
          "message_id" => msg_id
        },
        auth: {:bearer, Application.get_env(:whatsapp_cloud_api_wrapper, "META_WA_SENDER_PHONE_NUMBER_ID")}
      )
    end
  end

  def send_req(%{"to" => to} = params) do
    Req.post!(
      url: get_base_url(),
      headers: @default_headers,
      json:
        Map.merge(
          %{
            "messaging_product" => "whatsapp",
            "recipient_type" => "individual",
            "to" => to
          },
          params
        ),
      auth: {:bearer, Application.get_env(:whatsapp_cloud_api_wrapper, "META_WA_SENDER_PHONE_NUMBER_ID")}
    )
  end

  def send_text_msg(%{"message" => message, "recipientPhone" => recipient_phone} = params) do
    send_req(Map.put(params, "text", %{"body" => message, "preview_url" => false}))
  end

  def send_template_msg(%{"templateName" => name, "templateComponents" => components} = params) do
    req_body = %{
      "type" => "template",
      "template" => %{
        "name" => name,
        "language" => %{
          "code" => "en_US"
        },
        "components" => components
      }
    }

    send_req(req_body)
  end

  def send_interactive_msg(%{"message" => message, "listOfButtons" => listOfButtons} = params) do
    case validate_and_format_interactive_msg_buttons_list(listOfButtons) do
      {:ok, btn_list} ->
        send_req(
          Map.merge(
            params,
            %{
              "type" => "interactive",
              "interactive" => %{
                "type" => "button",
                "body" => %{"text" => message},
                "action" => %{"buttons" => btn_list}
              }
            }
          )
        )

      {:error, error} ->
        # todo: handle error better
        raise error

      _ ->
        # todo: handle error better
        raise ""
    end
  end

  def send_interactive_msg(
        %{
          "listOfSections" => listOfSections,
          "headerText" => headerText,
          "bodyText" => bodyText,
          "footerText" => footerText,
          # Todo: with check if this works with default text as "Select"
          "actionBtnText" => actionBtnText
        } = params
      ) do
    case validate_and_format_interactive_msg_sections_list(listOfSections) do
      {:ok, section_list} ->
        send_req(
          Map.merge(
            params,
            %{
              "type" => "interactive",
              "interactive" => %{
                "type" => "list",
                "header" => %{
                  "type" => "text",
                  "text" => headerText
                },
                "body" => %{"text" => bodyText},
                "footer" => %{"text" => footerText},
                "action" => %{
                  "button" => blank_default(actionBtnText, "Select"),
                  "section" => section_list
                }
              }
            }
          )
        )

      {:error, error} ->
        # todo: handle error better
        raise error

      _ ->
        # todo: handle error better
        raise ""
    end
  end

  # with url instead of file_path
  def send_media_msg(
        %{
          "recipientPhone" => recipientPhone,
          "caption" => caption,
          "fileName" => fileName,
          "url" => url,
          "type" => type
        } = params
      ) do
    req_body = %{
      "type" => type,
      type => %{
        "caption" => caption,
        "link" => url
      }
    }
    send_req(req_body)
  end

  # with filePath instead of url
  def send_media_msg(
        %{
          "recipientPhone" => recipientPhone,
          "caption" => caption,
          "filePath" => filePath,
          "fileName" => fileName
        } = params
      ) do
    # todo:
  end

  def send_location_msg() do
    # todo
  end

  def send_contact() do
    # todo
  end

  def send_message(%{"type" => type, "recipientPhone" => recipientPhone} = params) do
    case type do
      "text" ->
        send_text_msg(params)

      "template" ->
        send_template_msg(params)

      "radio_buttons" ->
        send_interactive_msg(params)

      "simple_buttons" ->
        send_interactive_msg(params)

      "image" ->
        send_media_msg(params)

      "video" ->
        send_media_msg(params)

      "audio" ->
        send_media_msg(params)

      "contacts" ->
        send_contact()

      "location" ->
        send_location_msg()

      _ ->
        raise "no type matched."
    end
  end

  def send_message(_) do
    # todo: missing params like  message, recipient_phone, type etc.; raise and handle gracefully.
  end
end
