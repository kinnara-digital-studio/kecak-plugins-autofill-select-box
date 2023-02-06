(function($) {
    $.fn.autofillSelectBox = function(arguments) {
        let $autofillSelectBox = this.kecakSelect2(arguments);

        return $autofillSelectBox;
    };

    $.fn.setTargetReadonly = function($field) {
        $field.attr('readonly', 'readonly');
        $field.attr('disabled', 'disabled');
    };

    $.fn.triggerSelect = function(value) {
        $(this).trigger({
            type: "select2:select",
            params: {
                value : value
            }
        });
    };

    $.fn.autofillField = function($target, value) {
        if($target.is(':checkbox, :radio')) {
            $target.each(function() {
                let multivalue = value.split(/;/);
                $(this).prop('checked', multivalue.indexOf($(this).val()) >= 0);
            });
        } else if($target.is('select')) {
            $target.triggerSelect(value);
        } else {
            $target.each(function() {
                $(this).val(value);
                $(this).trigger("change");
            });
        }
    };
})(jQuery);