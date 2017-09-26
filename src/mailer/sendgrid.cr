require "json"
require "base64"

module Mailer
  class SengridMessagePersonalisation
    def initialize
    end

    JSON.mapping({
      to:            {type: Array(Recipient), nilable: true},
      cc:            {type: Array(Recipient), nilable: true},
      bcc:           {type: Array(Recipient), nilable: true},
      subject:       {type: String, nilable: true},
      headers:       {type: Hash(String, String), nilable: true},
      substitutions: {type: Hash(String, String), nilable: true},
      custom_args:   {type: Hash(String, String), nilable: true},
      send_at:       {type: Int64, nilable: true}, # timestamp
    })
  end

  class SendgridContent
    def initialize(@type, @value)
    end

    JSON.mapping({
      type:  {type: String, nilable: true},
      value: {type: String, nilable: true},
    })
  end

  class SendgridAttachment
    def initialize(@content, @filename, @disposition, @content_id)
    end

    JSON.mapping({
      type:        {type: String, nilable: true},
      content:     {type: String, nilable: true},
      filename:    {type: String, nilable: true},
      disposition: {type: String, nilable: true}, # inline / attachment
      content_id:  {type: String, nilable: true}, # cid
    })
  end

  class SengridMessage
    def initialize
    end

    JSON.mapping({
      personalizations: {type: Array(SengridMessagePersonalisation), nilable: true},
      from:             {type: Recipient, nilable: true},
      reply_to:         {type: Recipient, nilable: true},
      subject:          {type: String, nilable: true},
      content:          {type: Array(SendgridContent), nilable: true},
      attachments:      {type: Array(SendgridAttachment), nilable: true},
    })
  end

  class Sendgrid < Mailer::Provider
    @key = ""

    # Setup sendgrid library with your api key
    #
    # ```ruby
    # Mailer::Sendgrid.setup(key: "your-key-here")
    # ```
    def initialize(@key)
    end

    # :nodoc:
    def self.key
      @key
    end

    def send(message)
      body = ""
      m = SengridMessage.new
      person = SengridMessagePersonalisation.new
      person.to = message.to.size > 0 ? message.to : nil
      person.cc = message.cc.size > 0 ? message.cc : nil
      person.bcc = message.bcc.size > 0 ? message.cc : nil
      m.personalizations = [person]
      content = [] of SendgridContent
      content << SendgridContent.new("text/plain", message.text) if message.text.size > 0
      content << SendgridContent.new("text/html", message.html) if message.html.size > 0
      m.content = content
      m.subject = message.subject
      m.from = Recipient.new(message.from)
      sg_attachments = [] of SendgridAttachment
      attachments = message.attachments
      inline = message.inline

      if attachments.size > 0
        attachments.each do |attachment|
          sg_attachments << SendgridAttachment.new(
            content: Base64.encode(::File.read(attachment.path)),
            filename: attachment.filename,
            disposition: "attachment",
            content_id: attachment.filename,
          )
        end
      end

      if inline.size > 0
        inline.each do |attachment|
          sg_attachments << SendgridAttachment.new(
            content: Base64.encode(::File.read(attachment.path)),
            filename: attachment.filename,
            disposition: "inline",
            content_id: attachment.filename,
          )
        end
      end

      m.attachments = sg_attachments.size > 0 ? sg_attachments : nil
      body = m.to_json
      client = HTTP::Client.new("api.sendgrid.com", tls: true)
      client.post("/v3/mail/send", headers: HTTP::Headers{
        "Host"           => "localhost",
        "Authorization"  => "Bearer #{@key}",
        "Content-Type"   => "application/json",
        "Content-Length" => body.size.to_s,
      }, body: body) do |response|
        if response && response.status_code == 202 # returns null on success
          return {"status" => "success", "data" => "sent"}
        else # 400 401 413
          return {"status" => "failed", "data" => JSON.parse(response.body_io.gets_to_end)}
        end
      end
    end

    private def add(multipart, name, val)
      multipart.body_part HTTP::Headers{"content-disposition" => %{form-data; name="#{name}"}}, val
    end

    private def add_file(multipart, filepath, filename, filetype = "attachment")
      multipart.body_part(HTTP::Headers{"content-disposition" => %{form-data; name="#{filetype}"; filename="#{filename}"}}) do |io|
        ::File.open(filepath, "r") do |file|
          IO.copy(file, io)
        end
      end
    end
  end
end
