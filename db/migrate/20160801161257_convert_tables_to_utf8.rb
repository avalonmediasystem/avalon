class ConvertTablesToUtf8 < ActiveRecord::Migration
  def change_encoding(encoding,collation)
    connection = ActiveRecord::Base.connection
    if connection.adapter_name == 'Mysql2'
      tables = connection.tables
      dbname = connection.current_database
      execute <<-SQL
        ALTER DATABASE #{dbname} CHARACTER SET #{encoding} COLLATE #{collation};
      SQL
      tables.each do |tablename|
        execute <<-SQL
          ALTER TABLE #{dbname}.#{tablename} CONVERT TO CHARACTER SET #{encoding} COLLATE #{collation};
        SQL
      end
    end
  end

  def up
    change_encoding('utf8','utf8_general_ci')
  end

  def down
    raise ActiveRecord::IrreversibleMigration
    #change_encoding('latin1','latin1_swedish_ci')
  end
end
