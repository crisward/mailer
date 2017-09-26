# Mailer

This project aims to provide a common api for popular email providers. It currently supports
* Mailgun
* Sendgrid

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  mailer:
    github: crisward/mailer
```

## Usage

```crystal
require "mailer"

Mailer.config(provider: Mailer::Mailgun.new(key: ENV["MAILGUN_KEY"], domain: ENV["MAILGUN_DOMAIN"]))
email = Mailer::Message.new
email.to("them@somedomain.com","their_name")
email.from = "you@yourdomain.com"
email.subject = "Hello"
email.text = "Some plain text messaeg"
email.html = "<p>Some html message <img src='cid:logo.jpg'></p>"
email.attachment = Mailer::Attachment.new(filename: "test.pdf" , path: "./spec/test.pdf")
email.inline = Mailer::Attachment.new(filename: "logo.jpg" , path: "./spec/test.png")
email.send
```


## Development

Running tests

```
# mock
crystal spec

#mailgun
MAILGUN_KEY="your-api-key" MAILGUN_DOMAIN="mailgun-domain" EMAIL="your@email.com" crystal spec

#sendgrid
SENDGRID_KEY="your-api-key" EMAIL="your@email.com" crystal spec

```

## Contributing

1. Fork it ( https://github.com/[your-github-name]/mailer/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[crisward]](https://github.com/crisward) Cris Ward - creator, maintainer
