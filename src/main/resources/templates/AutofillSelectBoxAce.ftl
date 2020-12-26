<div class="form-cell form-group" ${elementMetaData!}>
	<link rel="stylesheet" href="${request.contextPath}/plugin/${className}/bower_components/select2/dist/css/select2.min.css" />

    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/select2/dist/js/select2.min.js"></script>
    <#-- <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/jquery.autofillselectbox.js"></script> -->
    <script type="text/javascript" src="${request.contextPath}/js/json/formUtil.js"></script>
	
	<#assign elementId = elementParamName + element.properties.elementUniqueKey>
	
    <label class="control-label">${element.properties.label} <span class="form-cell-validator">${decoration}</span><#if error??> <span class="form-error-message">${error}</span></#if></label>

    <#if includeMetaData>
        <span class="form-floating-label">${fieldType}</span>
    </#if>

    <#if (element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
        <div class="form-cell-value">
            <#list options! as option>
                <#if values?? && values?seq_contains(option.value!)>
                    <label class="readonly_label">
                        <span>${option.label!?html}</span>
                        <input id="${elementParamName!}" name="${elementParamName!}" type="hidden" value="${option.value!?html}" />
                    </label>
                </#if>
            </#list>
        </div>
        <div style="clear:both;"></div>
    <#else>
        <select id="${elementId}" <#if element.properties.multiple! == 'true'>multiple</#if> name="${elementParamName!}" class="js-select2 form-control <#if error??>form-error-cell</#if>" <#if element.properties.readonly! == 'true'> disabled </#if>>
            <#if element.properties.lazyLoading! != 'true' >
                <#list options! as option>
                    <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                </#list>
            <#else>
                <#list options! as option>
                    <#if values?? && values?seq_contains(option.value!) || option.value == ''>
                        <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                    </#if>
                </#list>
            </#if>
        </select>
    </#if>
    <#if (element.properties.readonly! != 'true') >
        <img id="${elementId}_loading" src="${request.contextPath}/plugin/${className}/images/spin.gif" height="24" width="24" style="vertical-align: middle; display: none;">
    </#if>

    <#if element.properties.controlField?? && element.properties.controlField! != "" && !(element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
        <script type="text/javascript" src="${request.contextPath}/plugin/org.joget.apps.form.lib.SelectBox/js/jquery.dynamicoptions.js"></script>
        <script type="text/javascript">
            $(document).ready(function(){
                $("#${elementId}").dynamicOptions({
                    controlField : "${element.properties.controlFieldParamName!}",
                    paramName : "${elementParamName!}",
                    type : "selectbox",
                    readonly : "${element.properties.readonly!}",
                    nonce : "${element.properties.nonce!}",
                    binderData : "${element.properties.binderData!}",
                    appId : "${element.properties.appId!}",
                    appVersion : "${element.properties.appVersion!}",
                    contextPath : "${request.contextPath}"
                });
            });
        </script>
    </#if>
    
    <#if element.properties.readonly! != 'true' >
        <script type="text/javascript">
            $(document).ready(function(){
                $('#${elementId!}.js-select2').select2({
                    //placeholder: '${element.properties.placeholder!}',
                    width : '100%',
                    language : {
                       errorLoading: () => '${element.properties.messageErrorLoading!}',
                       loadingMore: () => '${element.properties.messageLoadingMore!}',
                       noResults: () => '${element.properties.messageNoResults!}',
                       searching: () => '${element.properties.messageSearching!}'
                    }

                    <#if element.properties.lazyLoading! == 'true' >
                        ,ajax: {
                            url: '${request.contextPath}/web/json/app/${appId!}/${appVersion!}/plugin/${className}/service',
                            delay : 500,
                            dataType: 'json',
                            data : function(params) {
                                return {
                                    search: params.term,
                                    appId : '${appId!}',
                                    appVersion : '${appVersion!}',
                                    formDefId : '${formDefId!}',
                                    fieldId : '${element.properties.id!}',
                                    <#if element.properties.controlField! != '' >
                                        grouping : FormUtil.getValue('${element.properties.controlField!}'),
                                    </#if>
                                    page : params.page || 1
                                };
                            }
                        }
                    </#if>
                });

                var prefix = "${elementId}".replace(/${element.properties.id!}${element.properties.elementUniqueKey!}$/, "");

                const TIMEOUT = 100;
                $('#${elementId}').change(() => setTimeout(trigger_${elementId}, TIMEOUT));

                <#if element.properties.triggerOnPageLoad! == 'true'>
                    $('#${elementId}').change();
                </#if>

                <#if element.properties.targetFieldAsReadonly! == 'true'>
                    <#list fieldsMapping?keys! as field>
                        {
                            let $selector = FormUtil.getField('${field!}');
                            <#--
                            $("[name='" + prefix + "${field!}']").each(function() {
                                $(this).attr('readonly', 'readonly');
                            });
                            -->

                            $selector.each(function() {
                                $(this).attr('readonly', 'readonly');
                            });
                        }
                    </#list>
                </#if>

                function trigger_${elementId}() {
                    <#if includeMetaData == false || requestBody?? >
                        var primaryKey = $('#${elementId}').val();
                        var url = '${request.contextPath}/web/json/app/${appId!}/${appVersion!}/plugin/${className}/service';

                        var jsonData = {
                            appId : '${appId!}',
                            appVersion : '${appVersion!}',
                            ${keyField} : primaryKey,
                            ...${requestBody!}
                        };

                        if(!(jsonData['FORM_ID'] && jsonData['FIELD_ID']))
                            return;

                        jsonData.autofillRequestParameter = new Object();

                        <#-- BETA -->
                        // set input fields as request parameter
                        var prefix = '${element.properties.customParameterName!}'.replace(/${element.properties.id}$/, '');
                        var patternPrefix = new RegExp('^' + prefix);

                        $('img#${elementId!}_loading').show();
                        $('input[name^="' + prefix + '"]').each(function() {
                            var name = $(this).attr('name');
                            if(name) {
                                jsonData.autofillRequestParameter[name.replace(patternPrefix, '')] = $(this).val();
                            }
                        });


                        $.ajax({
                            url: url,
                            type : 'POST',
                            headers : { 'Content-Type' : 'application/json' },
                            data : JSON.stringify(jsonData)
                        })
                        .done(function(data) {
                            $('img#${elementId!}_loading').hide();

                            <#-- clean up field if no lazy mapping -->
                            <#if element.properties.lazyMapping! != 'true' >
                                <#list fieldsMapping?keys! as field>
                                    {
                                        let $selector = FormUtil.getField('${field!}');

                                        <#assign fieldType = fieldTypes[field!]!>
                                        <#if fieldType! == 'RADIOS' >
                                            $selector.each(function() {
                                                $(this).prop('checked', false);
                                            });
                                        <#elseif fieldType! == 'CHECK_BOXES'>
                                            $selector.each(function() {
                                                $(this).prop('checked', false);
                                            });
                                        <#elseif fieldType! == 'GRIDS'>
                                            $("div.grid[name='" + prefix + "${field!}']").each(function() {
                                                <#-- remove previous grid row -->
                                                $(this).find('tr.grid-row').each(function() {
                                                    $(this).remove();
                                                });
                                            });
                                        <#elseif fieldType! == 'SELECT_BOXES'>
                                            $("select[name='" + prefix + "${field!}']").each(function() {
                                                $(this).val([]);
                                                $(this).trigger("chosen:updated"); <#-- if chosen is used -->
                                                $(this).trigger("change");  <#-- if select2 is used -->
                                            });
                                        <#else>
                                            $selector.each(function() {
                                                $(this).val('');
                                            });
                                        </#if>
                                    }
                                </#list>
                            </#if>

                            if(data.length == 0) {
                                return;
                            }

                            let i = 0;
                            let item = data;

                            <#list fieldsMapping?keys! as field>
                                if(item.${fieldsMapping[field]!}) {
                                    let $selector = FormUtil.getField('${field!}');

                                    if($selector.is(':checkbox, :radio')) {
                                        $selector.each(function() {
                                            var multivalue = item.${fieldsMapping[field]!}.split(/;/);
                                            $(this).prop('checked', multivalue.indexOf($(this).val()) >= 0);
                                        });
                                    } else if($selector.is('select')) {
                                        $("select[name='" + prefix + "${field!}']").each(function() {
                                            $(this).val(item.${fieldsMapping[field]!}.split(/;/)).trigger("change");
                                            $(this).trigger("chosen:updated");
                                        });
                                    } else {
                                        if(item.${fieldsMapping[field]!} || item.${fieldsMapping[field]!} == '') {
                                            <#assign fieldType = fieldTypes[field!]!>
                                            <!-- fieldType ${fieldType} -->
                                            <#if fieldType == 'LABEL'>
                                                $("div.subform-cell-value span[name='" + prefix + "${field!}']").each(function() {
                                                    if(!$(this).html() || '${element.properties.dontOverwrite!}' != 'true') {
                                                        $(this).html(item.${fieldsMapping[field]!});
                                                        $(this).trigger("change");
                                                    }
                                                });
                                            <#elseif fieldType! == 'GRIDS'>
                                                $("div.grid[name='" + prefix + "${field!}']").each(function() {
                                                    <#-- remove previous grid row -->
                                                    $(this).find('tr.grid-row').each(function() {
                                                        $(this).remove();
                                                    });

                                                    try {
                                                        var functionAdd = window[$(this).prop('id') + '_add'];
                                                        if(typeof functionAdd == 'function') {
                                                            var gridData = JSON.parse(item.${fieldsMapping[field]!});
                                                            for(var j in gridData) {
                                                                functionAdd({result : JSON.stringify(gridData[j])});
                                                            }
                                                        }
                                                    } catch (e) { }
                                                });
                                            <#else>
                                                $selector.each(function() {
                                                    if(!$(this).val() || '${element.properties.dontOverwrite!}' != 'true') {
                                                        $(this).val(item.${fieldsMapping[field]!});
                                                        $(this).trigger("change");
                                                    }
                                                });
                                            </#if>
                                        }
                                    }
                                }
                            </#list>
                        })
                        .fail(function() {
                            $('img#${elementId!}_loading').hide();
                            <#list element.properties.autofillFields! as field>
                                $("[name='" + prefix + "${field.formField!}']").val("");
                            </#list>
                        });
                    </#if>
                }
                <#if (element.properties.readonly! == 'true') >
                    $('#${elementId!} option:not(:selected)').attr('disabled', true);
                    $('#${elementId!}.js-select2').attr("disabled", true).trigger("change");
                </#if>
            });
        </script>
    </#if>
</div>
