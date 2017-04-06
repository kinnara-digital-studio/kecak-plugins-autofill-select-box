package com.kinnara.kecakplugins.autofillselectbox;

import java.util.HashMap;
import java.util.Map;

import org.joget.apps.app.dao.FormDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.FormDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.model.Element;
import org.joget.apps.form.model.Form;
import org.joget.apps.form.model.FormBinder;
import org.joget.apps.form.model.FormData;
import org.joget.apps.form.model.FormLoadElementBinder;
import org.joget.apps.form.model.FormRow;
import org.joget.apps.form.model.FormRowSet;
import org.joget.apps.form.service.FormService;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.json.JSONArray;
import org.springframework.context.ApplicationContext;

/**
 * 
 * @author aristo
 * 
 * Default form binder for element {@link AutofillSelectBox}
 * Load data from another form
 *
 */
public class AutofillFormBinder extends FormBinder  implements FormLoadElementBinder {
	private Map<String, Form> formCache = new HashMap<String, Form>();
	
	public FormRowSet load(Element element, String primaryKey, FormData formData) {			
		FormRowSet rowSet = new FormRowSet();
		Form form = generateForm(getPropertyString("formDefId"));
		
		if(form != null) {
			rowSet.add(loadFormData(form, formData));
		} else {
			LogUtil.warn(getClassName(), "Cannot generate form [" + getPropertyString("formDefId") + "]");
		}
		return rowSet;
	}

	public String getLabel() {
		return getName();
	}

	public String getClassName() {
		return getClass().getName();
	}

	public String getPropertyOptions() {
		return AppUtil.readPluginResource(getClassName(), "/properties/AutofillFormBinder.json", null, true, "/messages/AutofillFormBinder");
	}

	public String getName() {
		return "Kecak Autofill Form Binder";
	}

	public String getVersion() {
		return getClass().getPackage().getImplementationVersion();
	}

	public String getDescription() {
		return "Default Autofill Form Binder; Artifact ID : kecak-plugins-autofill-select-box";
	}

	private Form generateForm(String formDefId) {
		ApplicationContext appContext = AppUtil.getApplicationContext();
		FormService formService = (FormService) appContext.getBean("formService");
		FormDefinitionDao formDefinitionDao = (FormDefinitionDao)appContext.getBean("formDefinitionDao");
		
    	// check in cache
    	if(formCache != null && formCache.containsKey(formDefId))
    		return formCache.get(formDefId);
    	
    	// proceed without cache    	
        Form form = null;
        AppDefinition appDef = AppUtil.getCurrentAppDefinition();
        if (appDef != null && formDefId != null && !formDefId.isEmpty()) {
            FormDefinition formDef = formDefinitionDao.loadById(formDefId, appDef);
            if (formDef != null) {
                String json = formDef.getJson();
                form = (Form)formService.createElementFromJson(json);
                
                // put in cache if possible
                if(formCache != null)
                	formCache.put(formDefId, form);
                
                return form;
            }
        }
        return null;
	}
	
	private FormRow loadFormData(Form form, FormData formData) {		
		ApplicationContext appContext = AppUtil.getApplicationContext();
		FormService formService = (FormService) appContext.getBean("formService");
		
		formData = formService.executeFormLoadBinders(form, formData);
		
		FormRow row = new FormRow();
		getElementData(form, formData, row);
		
		return row;
	}
	
	private void getElementData(Element element, FormData formData, FormRow result) {
		FormRowSet rowSet = formData.getLoadBinderData(element);
		if(rowSet != null && !rowSet.isEmpty()) {
			if(rowSet.isMultiRow()) {
				String id = element.getPropertyString(FormUtil.PROPERTY_ID);
				result.setProperty(id, formRowSetToJson(rowSet).toString());
			} else {
				FormRow row = rowSet.get(0);
				for(Map.Entry entry : row.entrySet()) {
					if(!result.containsKey(entry.getKey()))
						result.setProperty(entry.getKey().toString(), entry.getValue().toString());
				}
			}
		}
				
		if(element.getChildren() != null) {
			for(Element child : element.getChildren()) {
				getElementData(child, formData, result);
			}
		}
	}
	
	private JSONArray formRowSetToJson(FormRowSet data) {
		if(data != null) {
			JSONArray result = new JSONArray();
			for(FormRow row : data) {
				result.put(row);
			}
			return result;
		}
		return null;
	}
}
