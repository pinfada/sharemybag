class OtpMailer < ApplicationMailer
  def delivery_code(recipient, code, validity_minutes)
    @recipient = recipient
    @code = code
    @validity_minutes = validity_minutes

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.otp.subject', default: "ShareMyBag - Your delivery confirmation code")
    )
  end
end
