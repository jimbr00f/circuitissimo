local commons = require("scripts.commons")

local items = {
    {
      type = 'item',
      name = commons.processor_name,
      icon_size = 64,
      icon = commons.png('item/processor'),
      subgroup = 'circuit-network',
      order = 'p[rocessor]',
      place_result = commons.processor_name,
      stack_size = 50,
      weight = 200000
  }, {
      type = "item-with-tags",
      name = commons.processor_with_tags,
      icon_size = 64,
      icon = commons.png('item/processor'),
      subgroup = 'circuit-network',
      order = 'p[rocessor]',
      place_result = commons.processor_name,
      stack_size = 1,
      flags = { "not-stackable" }
  }
}
data:extend(items)
