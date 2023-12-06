<<<<<<< HEAD
(function($){
    $.fn.extend({
        autofillSelectBox : function(params) {
            let $element = $(this);

            const TIMEOUT = 100;
            $element.change(() => setTimeout(() => $element.triggerOnChange(params), TIMEOUT));

            if(params.targetFieldAsReadonly) {
                for(const formField in params.targets) {
                    let $selector = FormUtil.getField(formField);

                    $selector.each(function() {
                        $(this).attr('readonly', 'readonly');
                        $(this).attr('disabled', 'disabled');
                    });

                    let shadowElement = '<input type="hidden" id="' + $selector.attr('id') + '_shadow" name="' + $selector.attr('name') + '" />';
                    $selector.parent().append(shadowElement);
                }
            }

            return $(this);
        },

        triggerOnChange : function(params) {
            let $element = $(this);

            let primaryKey = $element.val();
            let url = params.contextPath + '/web/json/app/' + params.appId + '/' + params.appVersion + '/plugin/' + params.className + '/service';

            let jsonData = {
                appId : params.appId,
                appVersion : params.appVersion,
                id : primaryKey,
                ...params.requestBody
            };

            jsonData.requestParameter = new Object();
            params.assets.$loadingImage.show();
            $.ajax({
                url: url,
                type : 'POST',
                headers : { 'Content-Type' : 'application/json' },
                data : JSON.stringify(jsonData)
            })
            .done(function(data) {
                params.assets.$loadingImage.hide();

                // clean up field if no lazy mapping
                for(const formField in params.targets) {
                    let $selectors = FormUtil.getField(formField);
                    let resultField = params.targets[formField];
                    let value = data[resultField];

                    if(value || value == '') {
                        $selectors.each(function() {
                            $selector = $(this);

                            if($selector.is(':checkbox, :radio')) {
                                let multivalue = value.split(/;/);
                                $selector.prop('checked', multivalue.indexOf($(this).val()) >= 0);
                            } else if($selector.is('select')) {
                                let multivalue = value.split(/;/);
                                $selector.val(multivalue).trigger("change");
                                $selector.trigger("chosen:updated");
                            } else {
                                $selector.val(value);
                                $selector.trigger("change");
                            }
                        });
                    }
                }
            })
            .fail(function() {
                params.assets.$loadingImage.hide();
            });
=======
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

    $.fn.clearField = function(fieldId) {
        let $selector = FormUtil.getField(fieldId);
        if($selector) {
            $selector.val('');
>>>>>>> v3
        }
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