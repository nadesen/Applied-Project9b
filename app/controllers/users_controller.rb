class UsersController < ApplicationController
  before_action :ensure_correct_user, only: [:update, :edit, :destroy]

  def show
    @user = User.find(params[:id])
    @books = @user.books
    @book = Book.new

    # 6日前〜今日（左→右）の投稿数
    @last_7_days_counts = (6).downto(0).map do |i|
      day = Time.zone.today - i.days
      @user.books.where(created_at: day.all_day).count
    end
  end

  def index
    @users = User.all
    @book = Book.new
    @book_new = Book.new
  end

  def edit
    @user = User.find(params[:id])
    unless @user == current_user
      redirect_to user_path(current_user)
    end
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "You have updated user successfully."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :introduction, :profile_image)
  end

  def ensure_correct_user
    @user = User.find(params[:id])
    unless @user == current_user
      redirect_to user_path(current_user)
    end
  end
end
