; extends

(
  (call
    function: (identifier) @func_name
    arguments: (argument_list
      [(string(string_content) @injection.content (#set! injection.language "sql")) (_(string(string_content) @injection.content (#set! injection.language "sql")))*]
    )
  )
  (#any-of? @func_name "DDL" "CheckConstraint" "text")
)
