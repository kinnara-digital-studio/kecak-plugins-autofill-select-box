<div class="form-cell" ${elementMetaData!}>
    <script type="text/javascript" src="${request.contextPath}/node_modules/select2/dist/js/select2.full.min.js"></script>
    <link rel="stylesheet" href="${request.contextPath}/node_modules/select2/dist/css/select2.min.css">
    <script type="text/javascript" src="${request.contextPath}/js/select2.kecak.js"></script>
    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/jquery.autofillselectbox.js"></script>

    <label class="label" for="${elementParamName!}${element.properties.elementUniqueKey!}" field-tooltip="${elementParamName!}">${element.properties.label} <span class="form-cell-validator">${decoration}</span><#if error??> <span class="form-error-message">${error}</span></#if></label>
    <#if (element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
        <div class="form-cell-value">
            <#list options as option>
                <#if values?? && values?seq_contains(option.value!)>
                    <label class="readonly_label">
                        <span>${option.label!?html}</span>
                    </label>
                </#if>
            </#list>
        </div>
        <div style="clear:both;"></div>
    <#else>
        <style>
            .select2-container {
                margin-bottom:18px !important;
            }

            .select2-search--dropdown .select2-search__field{
                float:none !important;
            }
        </style>
        <select class="js-select2" <#if element.properties.readonly! != 'true'>id="${elementParamName!}${element.properties.elementUniqueKey!}"</#if> name="${elementParamName!}" <#if element.properties.size?? && element.properties.size != ''> style="width:${element.properties.size!}%"</#if> <#if element.properties.multiple! == 'true'>multiple="multiple" data-role="none" data-native-menu="true"</#if> <#if error??>class="form-error-cell"</#if> <#if element.properties.readonly! == 'true'> disabled </#if>>
            <#if enableCrud?? && enableCrud == true && !(addEmptyOption?? && addEmptyOption)>
                <option value="__add_data__">+ Add Data</option>
            </#if>
            <#if element.properties.lazyLoading! != 'true' >
                <#list options as option>
                    <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if> <#if element.properties.readonly! == 'true'>disabled</#if>>${option.label!?html}</option>
                </#list>
            <#else>
                <#list options! as option>
                    <#if values?? && values?seq_contains(option.value!) || option.value == ''>
                        <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                    </#if>
                </#list>
            </#if>
            <#if enableCrud?? && enableCrud == true && (addEmptyOption?? && addEmptyOption)>
                <option value="__add_data__">+ Add Data</option>
            </#if>
        </select>
        <#if (element.properties.readonly! != 'true') >
            <img id="${elementParamName!}${element.properties.elementUniqueKey!}_loading" src="${request.contextPath}/plugin/${className}/images/spin.gif" height="24" width="24" style="margin :auto; top:0; position: absolute; display: none;">
        </#if>
    </#if>

    <#if element.properties.readonly! == 'true'>
        <#list values as value>
            <input type="hidden" id="${elementParamName!}" name="${elementParamName!}" value="${value?html}" />
        </#list>
    </#if>

    <#if (element.properties.controlField?? && element.properties.controlField! != "" && !(element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true')) >
        <script type="text/javascript">
            $(document).ready(function(){
                $("#${elementParamName!}${element.properties.elementUniqueKey!}").dynamicOptions({
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

    <#-- Select2 Implementation -->
    <script type="text/javascript">
        $(document).ready(function(){
            let $selectbox = $('select#${elementParamName!}${element.properties.elementUniqueKey!}.js-select2').kecakSelect2({
                dropdownAutoWidth : true,
                width : '${(element.properties.size)!"70"}%',
                theme : 'default',
                language : {
                   errorLoading: () => '${element.properties.messageErrorLoading!'@@form.selectbox.messageErrorLoading.value@@'}',
                   loadingMore: () => '${element.properties.messageLoadingMore!'@@form.selectbox.messageLoadingMore.value@@'}',
                   noResults: () => '${element.properties.messageNoResults!'@@form.selectbox.messageNoResults.value@@'}',
                   searching: () => '${element.properties.messageSearching!'@@form.selectbox.messageSearching.value@@'}'
                }

                <#if element.properties.lazyLoading! == 'true' && element.properties.controlField! != ''>
                    ,ajax: {
                        url: '${request.contextPath}/web/json/app/${appId!}/${appVersion!}/plugin/${className}/service',
                        delay : 500,
                        dataType: 'json',
                        data : function(params) {
                            return {
                                search: params.term,
                                formDefId : '${formDefId!}',
                                fieldId : '${element.properties.id!}',
                                nonce : "${element.properties.nonce!}",
                                binderData : "${element.properties.binderData!}",
                                grouping : FormUtil.getValue('${element.properties.controlField!}'),
                                page : params.page || 1
                            };
                        }
                    }
                </#if>
            })
            .autofillSelectBox({
                contextPath : '${request.contextPath}',
                appId : '${appId!}',
                appVersion : '${appVersion!}',
                elementId : '${element.properties.id!}',
                controlField : '${element.properties.controlField!}',
                targetFieldAsReadonly: ${(element.properties.targetFieldAsReadonly! == 'true')?string('true', 'false')},
                lazyMapping : ${(element.properties.lazyMapping! != 'true')?string('true', 'false')},
                requestBody : ${requestBody!},
                className : '${className}',
                assets : {
                    $loadingImage: $('img#${elementParamName!}${element.properties.elementUniqueKey!}_loading')
                },
                targets : ${fieldsMappingJson!}
            });

            let $select = $selectbox;

            let enableCrud = ${(enableCrud!false)?string('true','false')};
            let addEmptyOption = ${(addEmptyOption!false)?string('true','false')};

            if (enableCrud) {
                $select.find("option[value='__add_data__']").remove();

                if (addEmptyOption) {
                    let $empty = $select.find("option[value='']").first();

                    if ($empty.length) {
                        $('<option value="__add_data__">+ Add Data</option>')
                            .insertAfter($empty);
                    } else {
                        $select.prepend('<option value="__add_data__">+ Add Data</option>');
                    }

                } else {
                    $select.prepend('<option value="__add_data__">+ Add Data</option>');
                }

                $select.trigger('change.select2');
            }

            <#if element.properties.triggerOnPageLoad! == 'true'>
                setTimeout(() => $selectbox.change(), 1000);
            </#if>
        });
    </script>

    <#if enableCrud?? && enableCrud == true>
        <script type="text/javascript">
            function ${elementParamName!}_addDataCallback(args) {
                let result = typeof args.result === 'string' ? JSON.parse(args.result) : args.result;
                let newId = result.id || result.ID;
                
                let labelColumn = "${labelColumn!}";

                let newLabel = (labelColumn && result[labelColumn]) ? result[labelColumn] : newId;

                let $select = $('select#${elementParamName!}${element.properties.elementUniqueKey!}.js-select2');
                
                // 1. Adding new option to select
                let newOption = new Option(newLabel, newId, true, true);
                $select.append(newOption);
                
                // 2. Get all option expect for add data and empty option
                let $options = $select.find('option').filter(function() {
                    return $(this).val() !== '__add_data__' && $(this).val() !== '';
                });
                
                // 3. Sort by alph
                $options.sort(function(a, b) {
                    return a.text.localeCompare(b.text);
                });
                
                // 4. Insert sorted option to select
                $select.append($options);
                
                // 5. Trigger select to change
                $select.trigger('change');
                
                // 6. Hide form pop up
                if (window.JPopup) {
                    JPopup.hide("formPopup_${elementParamName!}");
                }
            }

            $(document).ready(function() {
                let frameId = "formPopup_${elementParamName!}";
                let $select = $('select#${elementParamName!}${element.properties.elementUniqueKey!}.js-select2');

                if (window.JPopup) {
                    JPopup.create(frameId, "Add Data", "80%", "80%");
                }

                $select.on('change', function (e) {
                    if ($(this).val() === '__add_data__') {
                        $(this).val(null).trigger('change.select2');
                        
                        let url = "${request.contextPath}/web/app/${appId!}/${appVersion!}/form/embed?_submitButtonLabel=Submit";
                        
                        if (typeof UI !== 'undefined' && typeof UI.userviewThemeParams === 'function') {
                            url += UI.userviewThemeParams();
                        } else if (window.ConnectionManager && window.ConnectionManager.tokenName) {
                            url += "&" + window.ConnectionManager.tokenName + "=" + window.ConnectionManager.tokenValue;
                        }

                        let params = {
                            _json: "${crudFormJson!?js_string}",
                            _callback: "${elementParamName!}_addDataCallback",
                            _nonce: "${crudFormNonce!?js_string}",
                            _setting: "{}"
                        };
                        
                        if (window.JPopup) {
                            JPopup.show(frameId, url, params, "", "80%", "80%");
                        } else {
                            console.error("JPopup script is not loaded in this environment.");
                        }
                    }
                });
            });
        </script>
    </#if>
</div>