class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update]
  before_action :load_user, only: [:show, :edit, :update, :correct_user]
  before_action :correct_user, only: [:show, :edit, :update]
  def index
    @users = User.all  
  end

  def showBooking
    redirect_to '/' unless logged_in?
    @working_logs = current_user.working_logs
    render :booking_part
  end

  def new
    redirect_to '/' if logged_in?
    @user = User.new
  end

  def create
    @user = User.new user_params
    if @user.save
      @user.send_activation_email
      flash[:success] = "Check mail to active your account!"
      redirect_to signin_path
    else
      flash[:error] = "Register failed"
      render :new
    end
  end

  def show; end

  def edit; end

  def update
    if @user.update_attributes user_params
      flash[:success] = "Update Successfully!"
      redirect_to @user
    else
      render :edit
    end
  end

  private

  def correct_user
    redirect_to root_path unless @user&.current_user? current_user
  end

  def user_params
    params.require(:user).permit User::USER_ATTRIBUTE
  end

  def load_user
    @user = User.find_by id: params[:id]

    return @user if @user
    flash[:error] = "User not found!"
    redirect_to root_path
  end
end
