class BugReportsController < AuthenticatedController
  before_action :authenticate_user! # Ensure the user is logged in

  def index
    load_bug_reports
    @new_bug_report = BugReport.new
  end

  def create
    load_bug_reports
    @new_bug_report = current_user.bug_reports.build(bug_report_params)
    if @new_bug_report.save
      redirect_to bug_reports_path, notice: 'Bug Report added successfully.'
    else
      render :index
    end
  end

  private

  def load_bug_reports
    @bug_reports = BugReport.left_joins(:votes)
                                      .group(:id)
                                      .order('COUNT(votes.id) DESC')
  end

  def bug_report_params
    params.require(:bug_report).permit(:title, :description)
  end
end

