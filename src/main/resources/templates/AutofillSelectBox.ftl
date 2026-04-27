<div class="form-cell" ${elementMetaData!}>
    <script type="text/javascript" src="${request.contextPath}/node_modules/select2/dist/js/select2.full.min.js"></script>
    <link rel="stylesheet" href="${request.contextPath}/node_modules/select2/dist/css/select2.min.css">
    <script type="text/javascript" src="${request.contextPath}/js/select2.kecak.js"></script>
    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/jquery.autofillselectbox.js"></script>
    
    <!-- ================= CONTROLLER ================= -->
    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/autofill-selectbox-crud.js"></script>

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
                margin-bottom: 0 !important; 
            }

            .select2-search--dropdown .select2-search__field{
                float:none !important;
            }
        </style>

        <div style="display:flex; align-items:center; gap:5px; margin-bottom:18px;">
        <select class="js-select2" <#if element.properties.readonly! != 'true'>id="${elementParamName!}${element.properties.elementUniqueKey!}"</#if> name="${elementParamName!}" <#if element.properties.size?? && element.properties.size != ''> style="width:${element.properties.size!}%"</#if> <#if element.properties.multiple! == 'true'>multiple="multiple" data-role="none" data-native-menu="true"</#if> <#if error??>class="form-error-cell"</#if> <#if element.properties.readonly! == 'true'> disabled </#if>>
            <#if enableCrud?? && enableCrud == true && !(addEmptyOption?? && addEmptyOption)>
                <option value="__add_data__">+ Add Data</option>
            </#if>
            <#if element.properties.lazyLoading! != 'true' >
                <#list options as option>
                        <option value="${option.value!?html}" data-id="${option.plainValue!}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if> <#if element.properties.readonly! == 'true'>disabled</#if>>${option.label!?html}</option>
                </#list>
            <#else>
                <#list options! as option>
                    <#if values?? && values?seq_contains(option.value!) || option.value == ''>
                        <option value="${option.value!?html}" data-id="${option.plainValue!}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                    </#if>
                </#list>
            </#if>
            <#if enableCrud?? && enableCrud == true && (addEmptyOption?? && addEmptyOption)>
                <option value="__add_data__">+ Add Data</option>
            </#if>
        </select>

        <#-- Show Edit Icon -->
        <#if addEdit?? && addEdit == true>
            <button type="button"
                id="${elementParamName!}_editBtn"
                style="display:none; padding:0 10px; cursor:pointer; height:28px; align-items:center; justify-content:center;" 
                class="btn btn-warning"> 
                <i class="fa fa-long-arrow-right" aria-hidden="true"></i>
            </button>
        </#if>

        <#-- Show Delete Icon-->
        <#if addDelete?? && addDelete == true>
            <button type="button"
                id="${elementParamName!}_deleteBtn"
                style="display:none; padding:0 10px; cursor:pointer; height:28px; align-items:center; justify-content:center;" 
                class="btn btn-danger"> 
                <i class="fa fa-trash" aria-hidden="true"></i>
            </button>
        </#if>

        <#if (element.properties.readonly! != 'true') >
            <img id="${elementParamName!}${element.properties.elementUniqueKey!}_loading" src="${request.contextPath}/plugin/${className}/images/spin.gif" height="24" width="24" style="display: none;">
        </#if>
        </div>
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

            <#if element.properties.triggerOnPageLoad! == 'true'>
                setTimeout(() => $selectbox.change(), 1000);
            </#if>

            AutofillSelectBoxCrudController.init($selectbox, {
                /* ================= BASIC ================= */
                paramName : '${elementParamName!}',
                contextPath : '${request.contextPath}',
                appId : '${appId!}',
                appVersion : '${appVersion!}',
                className : '${className}',

                /* ================= CRUD ================= */
                enableCrud : ${(enableCrud!false)?string('true','false')},
                addEmptyOption : ${(addEmptyOption!false)?string('true','false')},
                crudFormDefId : '${crudFormDefId!}',
                addEdit : ${(addEdit!false)?string('true','false')},
                addDelete : ${(addDelete!false)?string('true','false')},
                crudFormJson : '${crudFormJson!?js_string}',
                crudFormNonce : '${crudFormNonce!?js_string}',
                labelColumn: '${labelColumn!}',
                javascriptEnhancementOnFormLoad: ${element.properties.javascriptEnhancementOnFormLoad!'function($grid, $button) {}'}
            });

        });
    </script>
</div>