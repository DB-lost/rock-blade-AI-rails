class CreatePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :prompts do |t|
      t.text :template, null: false

      t.timestamps
    end
  end
end
