package com.kinnara.kecakplugins.autofillselectbox;

import org.joget.apps.app.dao.AppDefinitionDao;
import org.joget.apps.app.dao.FormDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.FormDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.model.*;
import org.joget.apps.form.service.FormService;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.json.JSONArray;
import org.springframework.context.ApplicationContext;

import java.util.HashMap;
import java.util.Map;

/**
 * 
 * @author aristo
 * 
 * Default form binder for element {@link AutofillSelectBox}
 * Load data from another form
 *
 */
public class AutofillFormBinder extends FormBinder  implements FormLoadElementBinder {
	private final Map<String, Form> formCache = new HashMap<>();
	
	public FormRowSet load(Element element, String primaryKey, FormData formData) {
		FormRowSet rowSet = new FormRowSet();

		String appId = formData.getRequestParameter("appId");
		String appVersion = formData.getRequestParameter("appVersion");

		AppDefinitionDao appDefinitionDao = (AppDefinitionDao) AppUtil.getApplicationContext().getBean("appDefinitionDao");
		AppDefinition appDefinition = appId == null ? AppUtil.getCurrentAppDefinition() : appDefinitionDao.findByVersion(null, appId, Long.getLong(appVersion), null, null, null, 0, 1)
				.stream()
				.findFirst()
				.orElse(null);

		Form form = generateForm(appDefinition, getPropertyString("formDefId"));
		
		if(form != null) {
			rowSet.add(loadFormData(form, formData));
		} else {
			LogUtil.warn(getClassName(), "Cannot generate form [" + getPropertyString("formDefId") + "] in app ["+appDefinition.getAppId()+"] version ["+appDefinition.getVersion()+"]");
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
		return "Autofill Form Binder";
	}

	public String getVersion() {
		return getClass().getPackage().getImplementationVersion();
	}

	public String getDescription() {
		return "Kecak Plugins; Default Autofill Form Binder; Artifact ID : " + getClass().getPackage().getImplementationTitle();
	}

	private Form generateForm(AppDefinition appDef, String formDefId) {
		ApplicationContext appContext = AppUtil.getApplicationContext();
		FormService formService = (FormService) appContext.getBean("formService");
		FormDefinitionDao formDefinitionDao = (FormDefinitionDao)appContext.getBean("formDefinitionDao");
		
    	// check in cache
    	if(formCache.containsKey(formDefId))
    		return formCache.get(formDefId);
    	
    	// proceed without cache
        if (appDef != null && formDefId != null && !formDefId.isEmpty()) {
            FormDefinition formDef = formDefinitionDao.loadById(formDefId, appDef);
            if (formDef != null) {
                String json = formDef.getJson();
				Form form = (Form)formService.createElementFromJson(json);

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
