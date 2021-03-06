class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    # @users = User.all
    @filterrific = initialize_filterrific(
            User,
            params[:filterrific],
            select_options: {
              sorted_by: User.options_for_sorted_by,
              with_gender: ['male', 'female'],
              range_level: [['0-4', '0'], ['5-9', '5'], ['10-14', '10'], ['15-19', '15']],
            }
          ) or return

    @users = @filterrific.find.page(params[:page]).per(20)
    # @users = User.page(params[:page]).per(20)
    @tag = 'all'
    respond_to do |format|
        format.html
        format.js
      end
  end

  def following
    @users = current_user.followings.page(params[:page]).per(20)
    @tag = 'following'
    render 'index'
  end

  def follower
    @users = current_user.followers.page(params[:page]).per(20)
    @tag = 'follower'
    render 'index'
  end

  def show
    # 使用者頁面可顯示：
    #   已經完成的任務
    #   所有的評價
    #   所有評價的數量
    #   尚未評價的數量
    #   current_user 可以去看哪些評價沒送出

    @user = User.find(params[:id])
    @missions = @user.missions_compeleted
    @instances = @user.instances.find_complete
    @reviews = @user.reviews.submited.order(updated_at: :desc)
    @unsended_reviews = @user.review_to_members.unsubmit

    @followings = @user.followings.last(3)

    respond_to do |format|
      format.html
      format.js
    end

  end

  def edit
    @user = User.find(params[:id])
    unless @user == current_user
      redirect_to user_path(current_user)
    end
  end

  def update

    @user = User.find(params[:id])

    if @user.update_attributes(user_params)
      flash[:notice] = "成功更新個人資料！"
      redirect_to user_path(@user)
    else
      flash[:alert] = "資料更新失敗！"
      render :edit
    end
  end


  def invite
    # ----說明-----
    # routes:
    #   透過POST invite_user_path(user) 來發送邀請
    # parameters:
    #   user_id: params[:id]
    #   instance_id: params[:instance_id]
    # 新增invitatoin:
    #  - invitation.user = current_user
    #  - invitation.invitee = user
    #  - invitation.instance = instance
    # ------------
    @instance = Instance.find(params[:instance_id])
    user = User.find(params[:id])

    #確認該使用者可以接受邀請
    if @instance.can_invite?(user)
      #產生邀請
      # binding.pry
      invitation = current_user.invitations.build(instance_id: @instance.id, invitee_id: user.id)
      invitation.save
      @notice_msg = '已送出邀請'

      @remaining_invitations_count = @instance.remaining_invitations_count
      @invitations = @instance.inviting_invitations.includes(:user)
      @filterrific = initialize_filterrific(
            User,
            params[:filterrific],
            select_options: {
              sorted_by: User.options_for_sorted_by,
              with_gender: ['male', 'female'],
              range_level: [['0-4', '0'], ['5-9', '5'], ['10-14', '10'], ['15-19', '15']],
            }
          ) or return
      @candidates = @filterrific.find.can_be_invited(@instance).page(params[:page])

      respond_to do |format|
        format.html
        format.js
      end

    else
      #不能收invite
      flash[:alert] = '不能送出邀請'
      redirect_back(fallback_location: root_path)
    end

  end

  private

  def user_params
    params.require(:user).permit(:name, :description, :avatar, :state, :available)
  end
end
