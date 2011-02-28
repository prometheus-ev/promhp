class OpenStruct

  undef_method :id
  alias_method :[], :send

end
