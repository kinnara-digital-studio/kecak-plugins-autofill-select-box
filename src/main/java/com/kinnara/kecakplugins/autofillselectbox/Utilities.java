package com.kinnara.kecakplugins.autofillselectbox;

import org.joget.apps.app.dao.DatalistDefinitionDao;
import org.joget.apps.app.dao.FormDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.DatalistDefinition;
import org.joget.apps.app.model.FormDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.datalist.model.DataList;
import org.joget.apps.datalist.model.DataListColumn;
import org.joget.apps.datalist.service.DataListService;
import org.joget.apps.form.model.Element;
import org.joget.apps.form.model.Form;
import org.joget.apps.form.model.Section;
import org.joget.apps.form.service.FormService;
import org.joget.commons.util.LogUtil;
import org.springframework.context.ApplicationContext;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;
import java.util.WeakHashMap;

public class Utilities {
    private final static Map<String, Form> formCache = new WeakHashMap<>();
    private final static Map<String, DataList> dataListCache = new WeakHashMap<>();

    public static Form generateForm(AppDefinition appDef, String formDefId) {
        // check in cache
        if(formCache.containsKey(formDefId)) {
            LogUtil.info(Utilities.class.getName(), "Retrieving form [" + formDefId + "] from cache");
//            return formCache.get(formDefId);
        }

        // proceed without cache
        Form form = null;
        if (appDef != null && formDefId != null && !formDefId.isEmpty()) {
            ApplicationContext appContext = AppUtil.getApplicationContext();
            FormService formService = (FormService) appContext.getBean("formService");
            FormDefinitionDao formDefinitionDao = (FormDefinitionDao)appContext.getBean("formDefinitionDao");

            FormDefinition formDef = formDefinitionDao.loadById(formDefId, appDef);
            if (formDef != null) {
                String json = formDef.getJson();
                form = (Form)formService.createElementFromJson(json);

                formCache.put(formDefId, form);
            }
        }

        return form;
    }

    public static DataList getDataList(ApplicationContext appContext, AppDefinition appDef, String dataListId) {
        if (dataListCache.containsKey(dataListId)) {
            LogUtil.info(Utilities.class.getName(), "Retrieving DataList from cache");
            return dataListCache.get(dataListId);
        }

        DataList dataList = null;
        if (dataListId != null && !dataListId.isEmpty()) {
            DataListService dataListService = (DataListService) appContext.getBean("dataListService");
            DatalistDefinitionDao datalistDefinitionDao = (DatalistDefinitionDao) appContext.getBean("datalistDefinitionDao");

            DatalistDefinition datalistDefinition = datalistDefinitionDao.loadById(dataListId, appDef);
            if (datalistDefinition != null) {
                dataList = dataListService.fromJson(datalistDefinition.getJson());
                ArrayList<DataListColumn> columns = new ArrayList<DataListColumn>();
                if (dataList.getColumns().length > 0) {
                    columns.addAll(Arrays.asList(dataList.getColumns()));
                }

                dataList.setColumns(columns.toArray(new DataListColumn[columns.size()]));
                dataList.setDefaultPageSize(DataList.MAXIMUM_PAGE_SIZE);
            }

            dataListCache.put(dataListId, dataList);
        }

        return dataList;
    }

    /**
     * get element's section
     *
     * @param element
     * @return
     */
    public static Section getElementSection(Element element) {
        if(element == null) {
            return null;
        }

        if(element instanceof Section) {
            return (Section) element;
        }

        return getElementSection(element.getParent());
    }
}
