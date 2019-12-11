class Partner < ApplicationRecord
  attr_reader :activation_token, :remember_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest

  mount_uploader :avatar, ImageUploader

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  PARTNER_ATTRIBUTE = [:name, :email, :avatar, :phone, :cost, :description, :city, :district, :password, :password_confirmation, :worktime_start, :worktime_end].freeze
  
  validates :name, presence: true, length: {maximum: 20}
  validates :email, presence: true, length: {maximum: 50},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}

  has_secure_password

  has_many :working_logs, dependent: :destroy
  
  def remember
    @remember_token = Partner.new_token
    update_attributes remember_digest: Partner.digest(remember_token)
  end

  def authenticated? attribute, token
    digest = send "#{attribute}_digest"

    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attributes remember_digest: nil
  end

  def current_partner? current_partner
    self == current_partner
  end

  def activate
    update_columns activated: true, activated_at: Time.zone.now
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def create_reset_digest
    @reset_token = Partner.new_token
    update_columns(reset_digest: Partner.digest(reset_token),
                   reset_sent_at: Time.zone.now)
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  class << self
    def digest string
      cost = Partner.choose_cost
      BCrypt::Password.create(string, cost: cost)
    end

    def choose_cost
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  private

  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    @activation_token = Partner.new_token
    self.activation_digest = Partner.digest activation_token
  end
end

