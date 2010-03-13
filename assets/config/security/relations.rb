AnnotationSecurity.define_relations do

  # All relations are defined in the context of a resource.
  # The block should return true iif the user has this relations.

#  all_resources do
#    administrator(:system, :is => :administrator)
#    owner_or_admin(:pretest){ owner or administrator }
#    owner(:system) { |user| user.status == :registered }
#  end

#  resource :album do
#    owner { |user, album| album.owner == user }
#  end

#  resource :picture do
#    owner "if owner: album"
#  end

end
