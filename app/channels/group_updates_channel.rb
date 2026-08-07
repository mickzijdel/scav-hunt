class GroupUpdatesChannel < ApplicationCable::Channel
  def subscribed
    # params[:user_id] is chosen by the client. This stream carries the rendered
    # challenge list, so without the check any signed-in user could read the
    # challenge groups another user has permission to see.
    user = User.find_by(id: params[:user_id])
    return reject if user.nil?
    return reject unless user == current_user || Ability.new(current_user).can?(:manage, GroupPermission)

    stream_for user
  end
end
