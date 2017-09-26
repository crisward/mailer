require "./provider"

  class Mailer::Mailgun < Mailer::Provider
    @apikey = ""
    @domain = ""

    # Setup mailgun library with your api key and domain
    #
    # ```crystal
    # Mailer::Mailgun.setup(key: "your-key-here", domain: "your-domain")
    # ```
    def initialize(key, domain)
      @apikey = key
      @domain = domain
    end

    # :nodoc:
    def self.apikey
      @apikey
    end

    # :nodoc:
    def self.domain
      @domain
    end

    def send(message)
      to = message.to.map { |recip| recip.to_s }.join(",")
      cc = message.cc.map { |recip| recip.to_s }.join(",")
      bcc = message.bcc.map { |recip| recip.to_s }.join(",")
      text = message.text
      html = message.html
      attachments = message.attachments
      inline = message.inline
      io = IO::Memory.new
      m = HTTP::Multipart::Builder.new(io)
      m.content_type("form-data")
      add m, "from", message.from
      add m, "to", to
      add m, "cc", cc if cc.size > 0
      add m, "bcc", bcc if bcc.size > 0
      add m, "subject", message.subject
      add m, "text", text if text.size > 0
      add m, "html", html if html.size > 0
      if attachments.size > 0
        attachments.each do |attachment|
          add_file m, attachment.path, attachment.filename
        end
      end
      if inline.size > 0
        inline.each do |attachment|
          add_file m, attachment.path, attachment.filename, "inline"
        end
      end
      m.finish
      client = HTTP::Client.new("api.mailgun.net", tls: true)
      client.basic_auth("api", @apikey)
      message = io.to_s
      if ENV["KEMAL_ENV"]? != "test" # prevent accidental email sending in kemal
        client.post("/v3/#{@domain}/messages", headers: HTTP::Headers{"Host" => "localhost", "Content-Type" => m.content_type("form-data"), "Content-Length" => message.size.to_s}, body: message) do |response|
          if response && response.status_code == 200
            return {"status" => "success", "data" => JSON.parse(response.body_io.gets_to_end)}
          else
            return {"status" => "failed", "data" => JSON.parse(response.body_io.gets_to_end)}
          end
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

