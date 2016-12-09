module MigrationComments
  module AnnotateModels
    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods
      def get_schema_info(*args)
        klass = args[0]
        klass.reset_column_information
        info = super(*args)
        commented_info(klass, info)
      end

      def commented_info(klass, info)
        table_name = klass.table_name
        adapter = klass.connection
        table_comment = adapter.retrieve_table_comment(table_name)
        column_comments = adapter.retrieve_column_comments(table_name)
        lines = []
        info.each_line{|l| lines << l.chomp}
        column_regex = /^#\s\*\*([`\w|*]+)\s+/
        len = lines.select{|l| l.starts_with? '# ------' }.first.length
        lines.each do |line|
          if line =~ /# Table name: |# table \+\w+\+ /
            line << " # #{table_comment}" if table_comment
          elsif line =~ column_regex
            column_name = $1.gsub(/[\*,`]/, '')
            comment = column_comments[column_name.to_sym]
            line << " " * (len - line.length)
            line << "|"
            line << " #{comment}" if comment
          elsif line.starts_with?('# Name')
            line << " " * (len - line.length)
            line << "| Comments"
          elsif line.starts_with?('# ------')
            line << "|"
            line << "-" * 25
          end
        end
        lines.join($/) + $/
      end
    end
  end
end
