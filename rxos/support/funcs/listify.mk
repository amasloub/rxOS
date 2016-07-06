define listify
$(foreach item,$1,\n    $(item))
endef
