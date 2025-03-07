class CreateToolUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :tool_usages do |t|
      t.string :function_name
      t.json :arguments
      t.text :result
      t.string :status
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end
  end
end
