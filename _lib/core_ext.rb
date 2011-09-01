class OpenStruct

  undef_method :id if method_defined?(:id)
  alias_method :[], :send

end
