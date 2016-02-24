function route_edit_setup(){
  $('#route-form').submit(function(event){
    $('#route-save').html('Saving...');
    $('#route-save').attr('disabled', 'disabled');
    $.ajax({
      url: $(this).attr('action'),
      method: '#{form_opts[:method].to_s.upcase}',
      data: {
        name: $('#name').val(),
        description: $('#description').val(),
        route_items: gather_route_items(true),
        configurators: gather_configurator_items()
      }
    });
    return false;
  });
}

function add_route_item(item_id, item_type){
  items = gather_route_items(true);
  items.push({type: item_type, id: item_id});
  $.post('#{add_service_routes_path}', {
    data: items
  });
}

function route_item_adder(){
  $.post('#{add_service_list_routes_path}', {
    data: gather_route_items()
  });
}

function gather_route_items(flat){
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

function gather_configurator_items(){
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

function configurator_edit(elm){
  $.post('#{edit_configurator_routes_path}', {
    data: gather_configurator_items(),
    configurator: elm.attr('data-configurator-name')
  });
}

function add_configurator_item(){
  item_name = $('#config-namer input').val();
  window_rails.close_window('configurator-namer');
  window_rails.loading.open();
  new_item = $('#config-template').clone();
  new_item.find('.configurator-item').attr('data-configurator-name', item_name);
  new_item.find('.configurator-item').attr('id', 'configurator-' + item_name);
  new_item.find('.configurator-item').find('.configurator-name').html(item_name);
  $('#configurator-adder-container').before(new_item.html());
  route_sort_setup();
  sparkle_ui.display.highlight('configurator-' + item_name);
  setTimeout(function(){
    configurator_edit($('#configurator-' + item_name));
    window_rails.loading.close();
  }, 1000);
}

function route_sort_setup(){
  $('.route-item-adder').click(route_item_adder);
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
    configurator_edit($(this));
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
      add_configurator_item();
    });
  });

  $('.config-sort').sortable({
    items: ".config-item"
  }).disableSelection();

}

$(document).ready(route_sort_setup);
$(document).ready(route_edit_setup);
