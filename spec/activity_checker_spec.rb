require_relative "../activity_checker"

describe ActivityChecker do

  def update_pr_diff_in_gh(number)
    file_name = "pr_#{number}.diff"
    file = 'spec/support/fixtures/Github/PRs_diff/' + file_name
    File.open(file, 'a') { |f| 
      f.puts @current_time
    }
  end

  before do
    @activity_checker = ActivityChecker.new
    @repo = "sasha-kantoriz/test"
    @current_time = Time.now.utc
    @config_reader = Config_reader.new
    @conf = @config_reader.get_activity_checker_configuration
  end

  context ".pr_has_label_for_ignoring?" do
    it "should return false if PR doesn't have any labels" do
      pr_without_labels = 3
      expect(@activity_checker.pr_has_label_for_ignoring?(@repo, pr_without_labels)).to be false
    end

    it "should return false if PR doesn't have labels for ignoring" do
      pr_with_another_labels = 4
      expect(@activity_checker.pr_has_label_for_ignoring?(@repo, pr_with_another_labels)).to be false
    end

    it "should return true if PR has label for ignoring" do
      pr_with_label_for_ignoring = 5
      expect(@activity_checker.pr_has_label_for_ignoring?(@repo, pr_with_label_for_ignoring)).to be true
    end
  end

  context ".new_pr_diff_sha" do
    it "should return false if PR diff_sha hasn't changed" do
      pr_with_unchanged_diff = 3
      expect(@activity_checker.new_pr_diff_sha(@repo, pr_with_unchanged_diff)).to be false
    end

    it "should return new diff_sha if PR diff_sha in DB is nil" do
      pr_without_diff_sha_field = 5
      expect(@activity_checker.new_pr_diff_sha(@repo, pr_without_diff_sha_field)).to be_truthy
    end

    it "should return new diff_sha if PR diff_sha has changed" do
      pr_with_new_diff = 4
      update_pr_diff_in_gh(4)
      expect(@activity_checker.new_pr_diff_sha(@repo, pr_with_new_diff)).to be_truthy
    end
  end

  context ".pr_inactive" do
    it "should return nil if PR is inactive less than 'timeout' from config" do
      not_outdated_pr = 4
      update_pr_diff_in_gh(4)
      expect(@activity_checker.pr_inactive(not_outdated_pr, @current_time)).to be_nil
    end

    it "should return days PR is inactive if diff_sha is unchanged more that 'timeout' from config" do
      outdated_pr = 3
      expect(@activity_checker.pr_inactive(outdated_pr, @current_time)).not_to be_nil
    end
  end

  context ".outdated_pr_need_notification?" do
    it "should return true
    if PR notified_at in DB is nil" do
      not_notified_outdated_pr = 5
      days_inactive = @activity_checker.pr_inactive(not_notified_outdated_pr, @current_time)

      expect(@activity_checker.outdated_pr_need_notification?(
        not_notified_outdated_pr, @current_time, days_inactive)
      ).to be true
    end

    it "should return false
    if outdated PR is inactive less than 30 days
    and was notified in last 3 days" do
      notified_outdated_pr = 10
      days_inactive = @activity_checker.pr_inactive(notified_outdated_pr, @current_time)

      expect(@activity_checker.outdated_pr_need_notification?(
        notified_outdated_pr, @current_time, days_inactive)
      ).to be false
    end

    it "should return true
    if outdated PR is inactive less than 30 days
    and hasn't been notified more than 3 days" do
      outdated_pr_to_notify = 9
      days_inactive = @activity_checker.pr_inactive(outdated_pr_to_notify, @current_time)
      notifiable_time = @current_time - 1 - 60 * 60 * 24 * 3
      @activity_checker.update_pr_notified_at(outdated_pr_to_notify, notifiable_time)

      expect(@activity_checker.outdated_pr_need_notification?(
        outdated_pr_to_notify, @current_time, days_inactive)
      ).to be true
    end

    it "should return false
    if outdated PR is inactive more than 30 days
    and was notified in last 10 days" do
      notified_outdated_pr = 3
      days_inactive = @activity_checker.pr_inactive(notified_outdated_pr, @current_time)

      expect(@activity_checker.outdated_pr_need_notification?(
        notified_outdated_pr, @current_time, days_inactive)
      ).to be false
    end

    it "should return true
    if outdated PR is inactive more than 30 days
    and hasn't been notified more than 10 days" do
      outdated_pr_to_notify = 6
      days_inactive = @activity_checker.pr_inactive(outdated_pr_to_notify, @current_time)
      notifiable_time = @current_time - 1 - 60 * 60 * 24 * 10
      @activity_checker.update_pr_notified_at(outdated_pr_to_notify, notifiable_time)

      expect(@activity_checker.outdated_pr_need_notification?(
        outdated_pr_to_notify, @current_time, days_inactive)
      ).to be true
    end
  end

  context ".get_pr_notificants" do
    it "should return default notify list
    if PR author is disabled or not in config 'profiles'" do
      pr_with_unknown_author = 7

      expect(@activity_checker.get_pr_notificants(
        pr_with_unknown_author
      )).to eq @conf[:recipients]
    end

    it "should return proper notify list
    if PR author is enabled in config 'profiles'" do
      pr_author_not_in_default = "@iwannabeer"
      pr_with_author_not_in_default = 6
      pr_notificants = (@conf[:recipients] + [pr_author_not_in_default]).uniq

      expect(@activity_checker.get_pr_notificants(
        pr_with_author_not_in_default
      )).to eq pr_notificants
    end

    it "should return notify list
    without duplicated users
    if PR author in default notify list" do
      pr_with_author_in_default_notify = 7

      expect(@activity_checker.get_pr_notificants(
        pr_with_author_in_default_notify
      )).to eq @conf[:recipients]
    end
  end

end