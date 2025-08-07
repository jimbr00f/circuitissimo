local common = require("scripts.common")

local items = {
    {
      type = 'item',
      name = common.processor_name,
      icon_size = 64,
      icon = common.png('item/processor'),
      subgroup = 'circuit-network',
      order = 'p[rocessor]',
      place_result = common.processor_name,
      stack_size = 50,
      weight = 200000
  }, {
      type = "item-with-tags",
      name = common.processor_with_tags,
      icon_size = 64,
      icon = common.png('item/processor'),
      subgroup = 'circuit-network',
      order = 'p[rocessor]',
      place_result = common.processor_name,
      stack_size = 1,
      flags = { "not-stackable" }
  }
}
data:extend(items)
