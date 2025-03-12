class CreateKnowledgeBases < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_bases do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # 添加索引以提高搜索性能
    add_index :knowledge_bases, :name
  end
end
