/**
 * Autofill SelectBox CRUD Controller
 */
(function () {

    if (window.AutofillSelectBoxCrudController) return;

    window.AutofillSelectBoxCrudController = {

        /* ================= STATE ================= */
        select: null,
        config: null,

        /* ================= INIT ================= */
        init: function ($select, config) {

            if (!$select || !$select.length) return;

            this.select = $select;
            this.config = config || {};

            this.prepareCrudOption();
            this.bindEvents();
            this.registerCrudCallbacks();
        },

        /* ================= ADD DATA OPTION POSITION ================= */
        prepareCrudOption: function () {

            const $select = this.select;

            if (this.config.enableCrud){
                $select.find("option[value='__add_data__']").remove();

                if (this.config.addEmptyOption) {
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
        },

        executeEnhancement: function ($trigger) {
            if (typeof this.config.javascriptEnhancementOnFormLoad === 'function') {
                this.config.javascriptEnhancementOnFormLoad(this.select, $trigger);
            }
        },

        /* ================= EVENTS ================= */
        bindEvents: function () {
            this.select.on("change", () => {
                const value = this.select.val();

                if (value === "__add_data__") {
                    this.select.val(null).trigger("change.select2");
                    this.executeEnhancement(this.select);
                    this.openPopup("add");
                    return;
                }
                this.toggleButtons(value);
            });

            if (this.config.addDelete) {
                $("#" + this.config.paramName + "_deleteBtn")
                    .off("click")
                    .on("click", () => this.deleteData());
            }

            if (this.config.addEdit) {
                const $editBtn = $("#" + this.config.paramName + "_editBtn");
                $editBtn
                    .off("click")
                    .on("click", () => {
                        this.executeEnhancement($editBtn);
                        this.openPopup("edit");
                    });
            }
        },

        /* ================= BUTTON VISIBILITY ================= */
        toggleButtons: function (value) {

            const $edit = $("#" + this.config.paramName + "_editBtn");
            const $delete = $("#" + this.config.paramName + "_deleteBtn");

            if (value && value !== "__add_data__") {
                if (this.config.addEdit) $edit.css("display", "flex");
                if (this.config.addDelete) $delete.css("display", "flex");
            } else {
                $edit.hide();
                $delete.hide();
            }
        },

        /* ================= DELETE ================= */
        deleteData: function () {

            const selectedId = this.select.val();
            if (!selectedId) return;

            if (!confirm("Are you sure you want to delete this data?")) return;

            $.ajax({
                url:
                    this.config.contextPath +
                    "/web/json/data/app/" +
                    this.config.appId +
                    "/form/" +
                    this.config.crudFormDefId +
                    "/" +
                    selectedId,
                type: "DELETE",
                success: () => {
                    this.select
                        .find("option[value='" + selectedId + "']")
                        .remove();

                    this.select.val(null).trigger("change");
                    alert("Data deleted successfully");
                }
            });
        },

        /* ================= POPUP ================= */
        openPopup: function (type) {

            const isEdit = type === "edit";
            const frameId = "formPopup_" + this.config.paramName;

            if (window.JPopup && !isEdit) {
                JPopup.create(
                    frameId,
                    "Add Data",
                    "80%",
                    "80%"
                );
            }

            let url =
                this.config.contextPath +
                "/web/app/" +
                this.config.appId +
                "/" +
                this.config.appVersion +
                "/form/embed?_submitButtonLabel=" +
                (isEdit ? "Save" : "Submit");

            if (typeof UI !== "undefined" && typeof UI.userviewThemeParams === "function") {
                url += UI.userviewThemeParams();
            } else if (window.ConnectionManager && window.ConnectionManager.tokenName) {
                url +=
                    "&" +
                    window.ConnectionManager.tokenName +
                    "=" +
                    window.ConnectionManager.tokenValue;
            }

            let params = {
                _json: this.config.crudFormJson,
                _callback:
                    this.config.paramName +
                    (isEdit ? "_editDataCallback" : "_addDataCallback"),
                _nonce: this.config.crudFormNonce,
                _setting: "{}",
                defaultValues: "{}"
            };

            if (isEdit) {

                const $select = this.select;
                let $selectedOption = $select.find(":selected");
                let encryptedId = $select.val();
                let plainId = $selectedOption.attr("data-id");

                if (!plainId) plainId = encryptedId;
                if (!plainId || plainId === "__add_data__") return;

                params.id = plainId;
            }

            if (window.JPopup) {
                JPopup.show(frameId, url, params, "", "80%", "80%");
            }
        },


        /* ================= REGISTER CALLBACK ================= */
        registerCrudCallbacks: function () {

            const self = this;

            /* ===== ADD CALLBACK ===== */
            window[this.config.paramName + "_addDataCallback"] = function (args) {

                let result =
                    typeof args.result === "string"
                        ? JSON.parse(args.result)
                        : args.result;

                let newId = result.id || result.ID;

                let labelColumn = self.config.labelColumn;
                let newLabel =
                    labelColumn && result[labelColumn]
                        ? result[labelColumn]
                        : newId;

                let newOption = new Option(newLabel, newId, true, true);
                self.select.append(newOption);

                self.select.trigger("change");

                if (window.JPopup) {
                    JPopup.hide("formPopup_" + self.config.paramName);
                }
            };

            /* ===== EDIT CALLBACK ===== */
            window[self.config.paramName + "_editDataCallback"] = function (args) {

                let result =
                    typeof args.result === "string"
                        ? JSON.parse(args.result)
                        : args.result;

                let editedId = result.id || result.ID;

                let labelColumn = self.config.labelColumn;
                let newLabel =
                    labelColumn && result[labelColumn]
                        ? result[labelColumn]
                        : editedId;

                self.select.find("option[value='" + editedId + "']").remove();

                let newOption = new Option(newLabel, editedId, true, true);

                self.select.append(newOption);

                self.select.trigger({
                    type: 'select2:select',
                    params: {
                        data: { id: editedId, text: newLabel }
                    }
                });

                self.select.val(editedId).trigger("change");

                if (window.JPopup) {
                    JPopup.hide("formPopup_" + self.config.paramName);
                }
            };
        },

    };

})();
