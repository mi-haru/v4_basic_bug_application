class RemoveUserRefFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_reference :posts, :user, foreign_key: true
  end
end
