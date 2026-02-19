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

            <#if addEdit?? && addEdit == true>
                // 1. Logic Visibility Button
                $select.on('change', function() {
                    let val = $(this).val();
                    let $editBtn = $("#${elementParamName!}_editBtn");
                    
                    // Tampilkan tombol HANYA jika value tidak kosong dan bukan __add_data__
                    if (val && val !== '' && val !== '__add_data__') {
                        $editBtn.css('display', 'flex'); 
                    } else {
                        $editBtn.hide();
                    }
                });
                
                // Trigger change saat load agar tombol muncul jika sudah ada data terpilih
                $select.trigger('change');

                // 2. Logic Click Handler untuk Edit Button
                $("#${elementParamName!}_editBtn").on('click', function() {
                    let $selectedOption = $select.find(':selected');
                    let encryptedId = $select.val();
                    
                    // Ambil Plain ID yang kita taruh di data-id tadi
                    let plainId = $selectedOption.attr('data-id');
                    
                    // Fallback: Jika tidak ada data-id (misal dari ajax tanpa mapping), coba pakai value (risiko error jika encrypted)
                    if (!plainId) plainId = encryptedId; 
                    
                    if (!plainId || plainId === '__add_data__') return;

                    let frameId = "formPopup_${elementParamName!}";
                    
                    // Buat URL Popup Edit
                    // Perhatikan kita menambahkan parameter &id=... agar form me-load data yang benar
                    let url = "${request.contextPath}/web/app/${appId!}/${appVersion!}/form/embed?_submitButtonLabel=Save";
                    
                    if (typeof UI !== 'undefined' && typeof UI.userviewThemeParams === 'function') {
                        url += UI.userviewThemeParams();
                    } else if (window.ConnectionManager && window.ConnectionManager.tokenName) {
                        url += "&" + window.ConnectionManager.tokenName + "=" + window.ConnectionManager.tokenValue;
                    }

                    // Passing parameters ke JPopup
                    let params = {
                        _json: "${crudFormJson!?js_string}",
                        _callback: "${elementParamName!}_editDataCallback", // Callback untuk Edit
                        _nonce: "${crudFormNonce!?js_string}",
                        _setting: "{}",
                        id: plainId // Send id to form loader
                    };
                    
                    if (window.JPopup) {
                        JPopup.show(frameId, url, params, "", "80%", "80%");
                    }
                });
            </#if>

            <#if addDelete?? && addDelete == true>
                // 1. Logic Visibility Button
                $select.on('change', function() {
                    let val = $(this).val();
                    let $deleteBtn = $("#${elementParamName!}_deleteBtn");
                    
                    // Tampilkan tombol HANYA jika value tidak kosong dan bukan __add_data__
                    if (val && val !== '' && val !== '__add_data__') {
                        $deleteBtn.css('display', 'flex');
                    } else {
                        $deleteBtn.hide();
                    }
                });
                
                // Trigger change saat load agar tombol muncul jika sudah ada data terpilih
                $select.trigger('change');

                // 2. Logic Click Handler untuk Delete Button
                $("#${elementParamName!}_deleteBtn").on('click', function() {
                    let $selectedOption = $select.find(':selected');
                    let encryptedId = $select.val();
                    let plainId = $selectedOption.attr('data-id');
                    if (!plainId) plainId = encryptedId;

                    if (!plainId || plainId === '__add_data__') return;

                    if (!confirm("Are you sure you want to delete this data?")) return;

                    let deleteUrl = "${request.contextPath}/web/json/data/app/${appId!}/form/${crudFormDefId!}/" + plainId;

                    $.ajax({
                        url: deleteUrl,
                        type: "DELETE",
                        headers: {
                            "Accept": "application/json",
                            "Content-Type": "application/json"
                        },
                        success: function(response) {
                            console.log("Success:", response);
                            // Hapus option dari select
                            $select.find("option[value='" + plainId + "']").remove();
                            $select.val(null).trigger('change');
                            alert("Data deleted successfully.");
                        },
                        error: function(xhr, status, error) {
                            console.error("AJAX Error Details:");
                            console.error("- Status Code:", xhr.status);
                            console.error("- Status Text:", xhr.statusText);
                            console.error("- Response Text:", xhr.responseText);
                            alert("Failed to delete data. Check console for details.");
                        }
                    });
                });
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
                
                // 3. Sort by alphabet
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

            function ${elementParamName!}_editDataCallback(args) {
                let result = typeof args.result === 'string' ? JSON.parse(args.result) : args.result;
                let editedId = result.id || result.ID;

                let labelColumn = "${labelColumn!}";
                let newLabel = (labelColumn && result[labelColumn]) ? result[labelColumn] : editedId;

                let $select = $('select#${elementParamName!}${element.properties.elementUniqueKey!}.js-select2');

                // Cari option yang sedang diedit
                let $option = $select.find("option[value='" + editedId + "']");

                if ($option.length) {
                    // Update text label
                    $option.text(newLabel);
                } else {
                    // Jika option belum ada (misalnya lazy loading)
                    let newOption = new Option(newLabel, editedId, true, true);
                    $select.append(newOption);
                }

                $select.trigger('change.select2');  
                $select.select2('destroy');

                $select.kecakSelect2({
                    dropdownAutoWidth : true,
                    width : '${(element.properties.size)!"70"}%',
                    theme : 'default'
                });

                // Re-select value agar select2 refresh
                $select.val(editedId).trigger('change');

                // Tutup popup
                if (window.JPopup) {
                    JPopup.hide("formPopup_${elementParamName!}");
                }
            }

            function ${elementParamName!}_deleteDataCallback(args) {
                 // Ambil ID yang dihapus
                let result = typeof args.result === 'string' ? JSON.parse(args.result) : args.result;
                let deletedId = result.id || result.ID;

                let $select = $('select#${elementParamName!}${element.properties.elementUniqueKey!}.js-select2');

                // Hapus option dari selectbox
                $select.find("option[value='" + deletedId + "']").remove();

                // Reset value dan trigger change
                $select.val(null).trigger('change');
                
                // Tutup popup
                if (window.JPopup) {
                    JPopup.hide("formPopupDelete_${elementParamName!}");
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