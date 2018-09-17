<div class="form-cell" ${elementMetaData!}>
	<link rel="stylesheet" href="${request.contextPath}/plugin/${className}/bower_components/select2/dist/css/select2.min.css" />
    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/select2/dist/js/select2.min.js"></script>
    <script type="text/javascript" src="${request.contextPath}/js/json/formUtil.js"></script>
	
	<#assign elementId = elementParamName + element.properties.elementUniqueKey>
	
    <label class="label">${element.properties.label} <span class="form-cell-validator">${decoration}</span><#if error??> <span class="form-error-message">${error}</span></#if></label>

    <#if includeMetaData>
        <span class="form-floating-label">${fieldType}</span>
    </#if>

    <#if (element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
        <div class="form-cell-value">
            <#list options as option>
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
        <select class="js-select2" id="${elementId}" name="${elementParamName!}" <#if element.properties.multiple! == 'true'>multiple</#if> <#if error??>class="form-error-cell"</#if>>
            <#if element.properties.lazyLoading! != 'true' >
                <!-- lazy loading -->
                <#list options as option>
                    <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                </#list>
            <#else>
                <!-- values -->
                <#list optionsValues as option>
                    <option value="${option.value!?html}" grouping="${option.grouping!?html}" selected>${option.label!?html}</option>
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
                    placeholder: '${element.properties.placeholder!}',
                    width : '${width!}',
                    theme : 'classic',
                    language : {
                       errorLoading: () => '${element.properties.messageErrorLoading!}',
                       loadingMore: () => '${element.properties.messageLoadingMore!}',
                       noResults: () => '${element.properties.messageNoResults!}',
                       searching: () => '${element.properties.messageSearching!}'
                    }

                    <#if element.properties.lazyLoading! == 'true' >
                        ,ajax: {
                            url: '${request.contextPath}/web/json/plugin/${className}/service',
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

                $('#${elementId}').change(trigger_${elementId});
                <#if element.properties.triggerOnPageLoad! == 'true'>
                    $('#${elementId}').change();
                </#if>

                function trigger_${elementId}() {
                    <#if includeMetaData == false || requestBody?? >
                        var primaryKey = $(this).val();
                        var url = "${request.contextPath}/web/json/plugin/${className}/service?${keyField}=" + primaryKey + "&appId=${appId}&appVersion=${appVersion}";

                        $('img#${elementId!}_loading').show();

                        var jsonData = ${requestBody!};
                        jsonData.autofillRequestParameter = new Object();

                        <#-- BETA -->
                        // set input fields as request parameter
                        var prefix = '${element.properties.customParameterName!}'.replace(/${element.properties.id}$/, '');
                        var patternPrefix = new RegExp('^' + prefix);

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

                            <#-- clean up field -->
                            <#list fieldsMapping?keys! as field>
                                <#assign fieldType = fieldTypes[field!]!>
                                <#if fieldType! == 'RADIOS' >
                                    $("input[name='" + prefix + "${field!}']").each(function() {
                                        $(this).prop('checked', false);

                                        <#if element.properties.targetFieldAsReadonly! == 'true'>
                                            $(this).attr('readonly', 'readonly');
                                        </#if>
                                    });
                                <#elseif fieldType! == 'CHECK_BOXES'>
                                    $("input[name='" + prefix + "${field!}']").each(function() {
                                        var multivalue = data[i].${fieldsMapping[field]!}.split(/;/);
                                        $(this).prop('checked', false);

                                        <#if element.properties.targetFieldAsReadonly! == 'true'>
                                            $(this).attr('readonly', 'readonly');
                                        </#if>
                                    });
                                <#elseif fieldType! == 'GRIDS'>
                                    $("div.grid[name='" + prefix + "${field!}']").each(function() {
                                        <#-- remove previous grid row -->
                                        $(this).find('tr.grid-row').each(function() {
                                            $(this).remove();
                                            <#if element.properties.targetFieldAsReadonly! == 'true'>
                                                $(this).attr('readonly', 'readonly');
                                            </#if>
                                        });
                                    });
                                <#elseif fieldType! == 'SELECT_BOXES'>
                                    $("select[name='" + prefix + "${field!}']").each(function() {
                                        $(this).val([]);
                                        $(this).trigger("chosen:updated"); <#-- if chosen is used -->
                                        $(this).trigger("change");  <#-- if select2 is used -->
                                        <#if element.properties.targetFieldAsReadonly! == 'true'>
                                            $(this).attr('readonly', 'readonly');
                                        </#if>
                                    });
                                <#else>
                                    $("[name='" + prefix + "${field!}']").each(function() {
                                        $(this).val('');
                                        <#if element.properties.targetFieldAsReadonly! == 'true'>
                                            $(this).attr('readonly', 'readonly');
                                        </#if>
                                    });
                                </#if>
                            </#list>

                            for(var i in data) {
                                if(data[i]) {
                                 <#list fieldsMapping?keys! as field>
                                    if(data[i].${fieldsMapping[field]!}) {
                                        <#assign fieldType = fieldTypes[field!]!>
                                        <#if fieldType == 'LABEL'>
                                            $("div.subform-cell-value span[id='" + prefix + "${field!}']").each(function() {
                                                $(this).html(data[i].${fieldsMapping[field]!});
                                                $(this).trigger("change");

                                            });
                                        <#elseif fieldType! == 'RADIOS' >
                                            $("input[name='" + prefix + "${field!}']").each(function() {
                                                $(this).prop('checked', $(this).val() == data[i].${fieldsMapping[field]!});
                                            });
                                        <#elseif fieldType! == 'CHECK_BOXES'>
                                            $("input[name='" + prefix + "${field!}']").each(function() {
                                                var multivalue = data[i].${fieldsMapping[field]!}.split(/;/);
                                                $(this).prop('checked', multivalue.indexOf($(this).val()) >= 0);
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
                                                        var gridData = JSON.parse(data[i].${fieldsMapping[field]!});
                                                        for(var j in gridData) {
                                                            functionAdd({result : JSON.stringify(gridData[j])});
                                                        }
                                                    }
                                                } catch (e) { }
                                            });
                                        <#elseif fieldType! == 'SELECT_BOXES'>
                                            $("select[name='" + prefix + "${field!}']").each(function() {
                                                $(this).val(data[i].${fieldsMapping[field]!}.split(/;/)).trigger("change");
                                                $(this).trigger("chosen:updated");
                                            });
                                        <#else>
                                            $("[name='" + prefix + "${field!}']").each(function() {
                                                $(this).val(data[i].${fieldsMapping[field]!});
                                                $(this).trigger("change");
                                            });
                                        </#if>
                                    }
                                </#list>
                                }
                            }
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
