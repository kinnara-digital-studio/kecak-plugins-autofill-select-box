package com.kinnara.kecakplugins.autofillselectbox;

import com.kinnarastudio.commons.jsonstream.JSONCollectors;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.model.*;
import org.joget.apps.form.service.FormService;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.joget.plugin.base.PluginManager;
import org.json.JSONArray;
import org.springframework.context.ApplicationContext;

import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.ResourceBundle;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * 
 * @author aristo
 * 
 * Default form binder for element {@link AutofillSelectBox}
 * Load data from another form
 *
 */
public class AutofillFormBinder extends FormBinder  implements FormLoadElementBinder {
	
	public FormRowSet load(Element element, String primaryKey, FormData formData) {
		FormRowSet rowSet = new FormRowSet();
		AppDefinition appDefinition = AppUtil.getCurrentAppDefinition();

		Form form = Utilities.generateForm(appDefinition, getPropertyString("formDefId"));
		
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
		PluginManager pluginManager = (PluginManager) AppUtil.getApplicationContext().getBean("pluginManager");
		ResourceBundle resourceBundle = pluginManager.getPluginMessageBundle(getClassName(), "/messages/BuildNumber");
		String buildNumber = resourceBundle.getString("buildNumber");
		return buildNumber;
	}

	public String getDescription() {
		return getClass().getPackage().getImplementationTitle();
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
	
	private JSONArray formRowSetToJson(FormRowSet rowSet) {
		return Optional.ofNullable(rowSet)
				.map(Collection::stream)
				.orElseGet(Stream::empty)
				.collect(JSONCollectors.toJSONArray());
	}
}
