class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.string :title, null: false
      t.references :assistant, null: false, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
