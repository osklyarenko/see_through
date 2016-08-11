class Profile

  attr_accessor :tz_shift, :login, :id, :slack_id, :email, :enable

  def initialize (login, email, id, slack_id, tz_shift, enable)
    @login = login
    @email = email
    @id = id
    @slack_id = slack_id
    @tz_shift = tz_shift
    @enable = enable
  end
end
