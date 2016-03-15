var fission_routes = {data: {}};

fission_routes.route_edit_setup = function(){
  $('#route-form').submit(function(event){
    $('#route-save').html('Saving...');
    $('#route-save').attr('disabled', 'disabled');
    $.ajax({
      url: $(this).attr('action'),
      method: $(this).attr('method'),
      data: {
        name: $('#name').val(),
        description: $('#description').val(),
        route_items: fission_routes.gather_route_items(true),
        configurators: fission_routes.gather_configurator_items()
      }
    });
    return false;
  });
}

fission_routes.add_route_item = function(item_id, item_type){
  items = fission_routes.gather_route_items(true);
  items.push({type: item_type, id: item_id});
  $.post(fission_routes.data['add_service_routes_path'], {
    data: items
  });
}

fission_routes.route_item_adder = function(){
  $.post(fission_routes.data['add_service_list_routes_path'], {
    data: fission_routes.gather_route_items()
  });
}

fission_routes.gather_route_items = function(flat){
  if(flat){
    items = [];
    $('.route-item').each(function(){
      items.push({
        type: $(this).attr('data-route-type'),
        id: $(this).attr('data-route-id')
      });
    });
    return items;
  } else {
    items = {};
    $('.route-item').each(function(){
      key = $(this).attr('data-route-type');
      if(!items[key]){
        items[key] = [];
      }
      items[key].push($(this).attr('data-route-id'));
    });
    return items;
  }
}

fission_routes.gather_configurator_items = function(){
  items = {};
  $('.configurator-item').each(function(){
    if($(this).attr('id') != 'configurator-template'){
      key = $(this).attr('data-configurator-name');
      items[key] = {configs: {}, matchers: {}, description: $(this).find('.description').val()};
      config_ids = [];
      $(this).find('.config').each(function(){
        config_ids.push($(this).val());
      });
      items[key]['configs'] = config_ids;
      $(this).find('.matcher').each(function(){
        items[key]['matchers'][$(this).attr('name')] = $(this).val();
      });
    }
  });
  return items;
}

fission_routes.configurator_edit = function(elm){
  $.post(fission_routes.data['edit_configurator_routes_path'], {
    data: fission_routes.gather_configurator_items(),
    configurator: elm.attr('data-configurator-name')
  });
}

fission_routes.add_configurator_item = function(){
  item_name = $('#config-namer input').val();
  window_rails.close_window('configurator-namer');
  window_rails.loading.open();
  new_item = $('#config-template').clone();
  new_item.find('.configurator-item').attr('data-configurator-name', item_name);
  new_item.find('.configurator-item').attr('id', 'configurator-' + item_name);
  new_item.find('.configurator-item').find('.configurator-name').html(item_name);
  $('#configurator-adder-container').before(new_item.html());
  fission_routes.route_sort_setup();
  sparkle_ui.display.highlight('configurator-' + item_name);
  setTimeout(function(){
    fission_routes.configurator_edit($('#configurator-' + item_name));
    window_rails.loading.close();
  }, 1000);
}

fission_routes.route_sort_setup = function(){
  $('.route-item-adder').click(fission_routes.route_item_adder);
  $('.route-sort').sortable({
    items: ".route-item"
  }).disableSelection();

  $('.route-item-delete, .config-item-delete').click(function(){
    elm = $(this).parents('.route-item, .config-item');
    panel = $(this).parents('.panel');
    sparkle_ui.display.highlight(panel.attr('id'), 'danger');
    setTimeout(function(item){
      item.toggle('fade');
    }, 1000, elm);
    setTimeout(function(item){
      item.remove();
    }, 1500, elm);
  });

  $('.configurator-item').click(function(){
    fission_routes.configurator_edit($(this));
  });

  $('.configurator-item-adder').click(function(){
    config_namer = $('#config-namer-template').clone();
    config_namer.find('.configurator-namer').attr('id', 'config-namer');
    args = {
      name: 'configurator-namer',
      content: config_namer.html(),
      size: 'small',
      title: 'New Rule Name'
    };
    window_rails.create_window(args);
    window_rails.open_window(args['name'], args);
    $('.configurator-name-saver button').click(function(){
      fission_routes.add_configurator_item();
    });
  });

  $('.config-sort').sortable({
    items: ".config-item"
  }).disableSelection();

}
