<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib uri="/WEB-INF/struts-tiles.tld" prefix="tiles" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im"%>

<!-- begin.jsp -->
<html:xhtml/>

<%-- Build a query --%>
<c:set var="helpUrl" value="${WEB_PROPERTIES['project.helpLocation']}/manual/manualClasschooser.html"/>
<im:box helpUrl="${helpUrl}"
        titleKey="begin.heading.build">
  <table border="0" cellspacing="0" cellpadding="0" width="100%">
    <tr>
      <td width="99%">
      	<c:choose>
      	  <c:when test="${!empty DATASETS && false}">
      	    <tiles:insert page="/dataSetIcons.jsp"/>
      	  </c:when>
      	  <c:otherwise>
      	  	<c:forEach items="${CATEGORIES}" var="category">
              <c:if test="${!empty CATEGORY_CLASSES[category]}">
                <div class="heading"><c:out value="${category}"/></div>
                <div class="body">
                  <c:set var="classes" value="${CATEGORY_CLASSES[category]}"/>
                  <c:forEach items="${classes}" var="classname" varStatus="status">
                    <a href="<html:rewrite page="/queryClassSelect.do"/>?action=<fmt:message key="button.selectClass"/>&amp;className=${classname}" title="<c:out value="${classDescriptions[classname]}"/>">
                    ${classname}</a><c:if test="${!status.last}">,</c:if>
                  </c:forEach>
                  <c:if test="${!empty CATEGORY_TEMPLATES[category]}">
                    <br/><span class="smallnote"><fmt:message key="begin.or"/> <html:link action="/templates" paramId="category" paramName="category"><fmt:message key="begin.related.templates"/></html:link></span>
                  </c:if>
                </div>
                <im:vspacer height="5"/>
              </c:if>
            </c:forEach>
      	  </c:otherwise>
      	</c:choose>
        <%--
        <c:forEach items="${CATEGORIES}" var="category">
          <c:if test="${!empty CATEGORY_CLASSES[category]}">
            <div class="heading"><c:out value="${category}"/></div>
            <div class="body">
              <c:set var="classes" value="${CATEGORY_CLASSES[category]}"/>
              <c:forEach items="${classes}" var="classname" varStatus="status">
                <a href="<html:rewrite page="/queryClassSelect.do"/>?action=<fmt:message key="button.selectClass"/>&amp;className=${classname}" title="<c:out value="${classDescriptions[classname]}"/>">
                ${classname}</a><c:if test="${!status.last}">,</c:if>
              </c:forEach>
              <c:if test="${!empty CATEGORY_TEMPLATES[category]}">
                <br/><span class="smallnote"><fmt:message key="begin.or"/> <html:link action="/templates" paramId="category" paramName="category"><fmt:message key="begin.related.templates"/></html:link></span>
              </c:if>
            </div>
            <im:vspacer height="5"/>
          </c:if>
        </c:forEach>
        --%>
        
      </td>
      <td valign="top" align="right" nowrap="nowrap" width="1%" class="buildmenu">
        <div class="body">
          <html:link action="/bagBuild">
            <fmt:message key="begin.upload.identifiers"/>
            <img border="0" class="arrow" src="images/right-arrow.gif" alt="->"/>
          </html:link><br/>
          <html:link action="/classChooser">
            <fmt:message key="begin.list.all.classes"/>
            <img border="0" class="arrow" src="images/right-arrow.gif" alt="->"/>
          </html:link><br/>
          <html:link action="/tree">
            <fmt:message key="begin.browse.model"/>
            <img border="0" class="arrow" src="images/right-arrow.gif" alt="->"/>
          </html:link><br/>
        </div>
      </td>
    </tr>
  </table>
</im:box>
<%-- /Build a query --%>



<%-- Browse - only show if begin.browse.template has been defined in model web.properties --%>
<c:set var="helpUrl" value="${WEB_PROPERTIES['project.helpLocation']}/manual/manualQuickStartBrowsing.html"/>
<c:if test="${!empty browseTemplateName && !empty GLOBAL_TEMPLATE_QUERIES[browseTemplateName]}">
  <im:vspacer height="12"/>
  <im:box helpUrl="${helpUrl}"
          titleKey="begin.heading.browse">
    <div class="body" align="center">
      <html:form action="/browseAction">
        ${WEB_PROPERTIES["begin.browse.prompt"]}:&nbsp;
        <html:hidden property="attributeOps(1)" value="${browseOperator}"/>
        <html:text property="attributeValues(1)"/>
        <input type="hidden" name="templateType" value="global"/>
        <input type="hidden" name="queryName" value="${browseTemplateName}"/>
        <input type="hidden" name="skipBuilder" value="1"/>
        <input type="hidden" name="noSaveQuery" value="1"/>
        <html:submit><fmt:message key="begin.input.submit"/></html:submit>
        <br/>
        <div class="smallnote">
          <fmt:message key="begin.browse.help.message"/>
          [<html:link href="${helpUrl}"><fmt:message key="begin.link.help"/></html:link>]
        </div>
      </html:form>
    </div>
  </im:box>
</c:if>

<c:if test="${IS_SUPERUSER && !empty browseTemplateName && empty GLOBAL_TEMPLATE_QUERIES[browseTemplateName]}">
  <im:vspacer height="12"/>
  <div class="altmessage">
    <fmt:message key="begin.noBrowseTemplate">
      <fmt:param value="${browseTemplateName}"/>
    </fmt:message>
  </div>
</c:if>
<%-- /Browse --%>

<c:set var="helpUrl" value="${WEB_PROPERTIES['project.helpLocation']}/manual/manualQuickStartTemplates.html"/>

<c:if test="${!IS_SUPERUSER}">
  <im:vspacer height="12"/>
  <im:box helpUrl="${helpUrl}" titleKey="begin.heading.templates">
    <c:forEach items="${CATEGORIES}" var="category">
      <c:if test="${!empty CATEGORY_TEMPLATES[category]}">
        <im:heading id="globalTmpls${category}">${category}</im:heading>
        <im:body id="globalTmpls${category}"><im:templateList type="global" category="${category}"/></im:body>
        <im:vspacer height="5"/>
      </c:if>
    </c:forEach>
    <c:if test="${empty GLOBAL_TEMPLATE_QUERIES}">
      <div class="altmessage"><fmt:message key="templateList.noTemplates"/></div>
    </c:if>
  </im:box>
</c:if>

<c:if test="${!empty PROFILE.categoryTemplates}">
  <im:vspacer height="12"/>
  <im:box helpUrl="${helpUrl}" titleKey="begin.heading.mytemplates">
    <c:forEach items="${PROFILE.categoryTemplates}" var="entry">
      <c:if test="${!empty entry.value && !empty entry.key}">
        <im:heading id="userTmpls${entry.key}">${entry.key}</im:heading>
        <im:body id="userTmpls${entry.key}"><im:templateList type="user" category="${entry.key}"/></im:body>
        <im:vspacer height="5"/>
      </c:if>
    </c:forEach>
    <c:if test="${!empty PROFILE.categoryTemplates['']}">
      <div class="heading"><fmt:message key="begin.noCategory"/></div>
      <div class="body"><im:templateList type="user" category=""/></div>
    </c:if>
  </im:box>
</c:if>
  
<c:if test="${IS_SUPERUSER}">
  <span class="smallnote">
    <c:if test="${!empty PROFILE.savedTemplates}">
      <html:link action="/exportTemplates?type=user" titleKey="begin.exportTemplatesDesc">
        <fmt:message key="begin.exportTemplates"/>
      </html:link><br/>
    </c:if>
    <html:link action="/import" titleKey="begin.importTemplatesDesc">
      <fmt:message key="begin.importTemplates"/>
    </html:link>
  </span>
</c:if>
<!-- /begin.jsp -->
