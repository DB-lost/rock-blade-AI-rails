class ChangeSourceTypeToStringInKnowledgeEntries < ActiveRecord::Migration[8.0]
  def up
    # 先添加临时的字符串字段
    add_column :knowledge_entries, :source_type_str, :string

    # 数据迁移
    execute <<-SQL
      UPDATE knowledge_entries
      SET source_type_str = CASE source_type
        WHEN 0 THEN 'directory'
        WHEN 1 THEN 'url'
        WHEN 2 THEN 'note'
        WHEN 4 THEN 'file'
        ELSE 'unknown'
      END;
    SQL

    # 删除旧的整数字段
    remove_column :knowledge_entries, :source_type

    # 重命名新字段
    rename_column :knowledge_entries, :source_type_str, :source_type

    # 添加非空约束和索引
    change_column_null :knowledge_entries, :source_type, false
    add_index :knowledge_entries, :source_type
  end

  def down
    # 先添加临时的整数字段
    add_column :knowledge_entries, :source_type_int, :integer

    # 数据回迁
    execute <<-SQL
      UPDATE knowledge_entries
      SET source_type_int = CASE source_type
        WHEN 'directory' THEN 0
        WHEN 'url' THEN 1
        WHEN 'note' THEN 2
        WHEN 'file' THEN 4
        ELSE 0
      END;
    SQL

    # 删除字符串字段
    remove_column :knowledge_entries, :source_type

    # 重命名新字段
    rename_column :knowledge_entries, :source_type_int, :source_type

    # 添加非空约束和索引
    change_column_null :knowledge_entries, :source_type, false
    change_column_default :knowledge_entries, :source_type, 0
    add_index :knowledge_entries, :source_type
  end
end
