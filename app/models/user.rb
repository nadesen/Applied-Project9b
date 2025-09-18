class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :books, dependent: :destroy
  has_one_attached :profile_image
  has_many :book_comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :active_relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
  has_many :followings, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  validates :name, presence: true, uniqueness: true, length: { minimum: 2, maximum: 20 }
  validates :introduction, length: { maximum: 50 }

  def follow(user)
    active_relationships.create(followed_id: user.id)
  end

  def unfollow(user)
    active_relationships.find_by(followed_id: user.id).destroy
  end

  def following?(user)
    followings.include?(user)
  end

  def self.search_for(content, method)
    if method == "perfect"
      User.where(name: content)
    elsif method == "forward"
      User.where("name LIKE ?", content + "%")
    elsif method == "backward"
      User.where("name LIKE ?", "%" + content)
    else
      User.where("name LIKE ?", "%" + content + "%")
    end
  end

  # 今日の投稿数
  def todays_books_count
    books.where(created_at: Time.zone.today.all_day).count
  end

  # 前日の投稿数
  def yesterdays_books_count
    books.where(created_at: (Time.zone.yesterday.all_day)).count
  end

  # 今日と前日の投稿数の差（比率：今日/前日、小数点2桁）
  def compare_today_and_yesterday
    yd = yesterdays_books_count
    yd > 0 ? (todays_books_count.to_f / yd).round(2) : "―"
  end

  # 今週の投稿数（今日含む直近7日間）
  def this_week_books_count
    from = Time.zone.today - 6.days
    to = Time.zone.today.end_of_day
    books.where(created_at: from.beginning_of_day..to).count
  end

  # 先週の投稿数（8日前～14日前）
  def last_week_books_count
    from = Time.zone.today - 13.days
    to = Time.zone.today - 7.days
    books.where(created_at: from.beginning_of_day..to.end_of_day).count
  end

  # 今週と先週の投稿数の差（比率：今週/先週、小数点2桁）
  def compare_this_and_last_week
    lw = last_week_books_count
    lw > 0 ? (this_week_books_count.to_f / lw).round(2) : "―"
  end

  # 過去7日間の投稿数を配列で返す（[今日, 1日前, ..., 6日前]）
  def last_7_days_books_counts_reverse
    (0..6).to_a.reverse.map do |i|
      day = Time.zone.today - i.days
      books.where(created_at: day.all_day).count
    end
  end
  
  def get_profile_image
    if profile_image.attached?
      profile_image
    else
      'no_image.jpg'
    end
  end
end
