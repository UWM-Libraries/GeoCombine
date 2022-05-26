<!--
     iso2geoBl.xsl - Transformation from ISO 19139 XML into GeoBlacklight solr json

-->
<xsl:stylesheet xmlns="http://www.loc.gov/mods/v3" xmlns:gco="http://www.isotc211.org/2005/gco"
  xmlns:gmi="http://www.isotc211.org/2005/gmi" xmlns:gmd="http://www.isotc211.org/2005/gmd"
  xmlns:gml="http://www.opengis.net/gml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="gml gmd gco gmi xsl">
  <xsl:output method="text" encoding="UTF-8" version="1.0" omit-xml-declaration="yes" indent="yes"
    media-type="application/json"/>
  <xsl:strip-space elements="*"/>
  <xsl:param name="zipName" select="'data.zip'"/>

  <xsl:template match="/">
    <!-- institution. This selects the individual name element if it is coded as 'resourceProvider'. AGSL is using that element to specifiy the institution, though it's probably more properly used for an individual creating the metadata. This definition needs to be more generalized and codified. OGM Aardvark recommends a controlled list for this based on the institutions that are using GeoBlacklight so they can be associated with logos. Since we don't have that, we'll just go with what we've got.  -->
    <xsl:variable name="institution"
      select="gmd:MD_Metadata/gmd:contact/gmd:CI_ResponsibleParty/gmd:individualName[following-sibling::gmd:role/gmd:CI_RoleCode[text() = 'resourceProvider']]/gco:CharacterString"/>
    <xsl:variable name="upperCorner">
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"
      />
    </xsl:variable>

    <xsl:variable name="lowerCorner">
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"
      />
    </xsl:variable>

    <xsl:variable name="x2"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/>
    <!-- E -->
    <xsl:variable name="x1"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/>
    <!-- W -->
    <xsl:variable name="y2"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"/>
    <!-- N -->
    <xsl:variable name="y1"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"/>
    <!-- S -->

    <xsl:variable name="format">
      <xsl:choose>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Raster Dataset')">
          <xsl:text>image/tiff</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'GeoTIFF')">
          <xsl:text>image/tiff</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Shapefile')">
          <xsl:text>application/x-esri-shapefile</xsl:text>
        </xsl:when>
        <xsl:when
          test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue = 'vector'">
          <xsl:text>application/x-esri-shapefile</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="uuid">
      <xsl:value-of select="gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"/>
    </xsl:variable>

    <xsl:variable name="identifier">
      <xsl:choose>
        <!-- for Stanford URIs -->
        <xsl:when test="contains($uuid, 'purl')">
          <xsl:value-of select="substring($uuid, string-length($uuid) - 10)"/>
        </xsl:when>
        <!-- all others -->
        <xsl:otherwise>
          <xsl:value-of select="$uuid"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Transformation scenarios -->
    <!-- Schema declaration. -->
    <xsl:text>{"$schema": "https://raw.githubusercontent.com/UWM-Libraries/geoblacklight/main/schema/geoblacklight-schema-aardvark.json",</xsl:text>
    <!-- 01. Title element. Required. Not repeatable -->
    <xsl:text>"dct_title_s": "</xsl:text>
    <xsl:value-of
      select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"/>
    <xsl:text>",</xsl:text>
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract">
      <!-- 02. Alternative Title element. Optional. Repeatable. Not implemented. -->
      <!-- 03. Description element. Recommended. Repeatable -->
      <xsl:text>"dct_description_sm": [</xsl:text>
      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="gco:CharacterString"/>
        <xsl:text>"</xsl:text>
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>
    <!-- 04. Language element. Optional. Repeatable -->
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language">
      <xsl:text>"dct_language_sm": [</xsl:text>
      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="gmd:LanguageCode"/>
        <xsl:text>"</xsl:text>
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>
    <!-- 05. Creator element. Recommended. Repeatable -->
    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'originator']">
      <xsl:text>"dct_creator_sm": [</xsl:text>

      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'originator']">
        <xsl:if test="ancestor-or-self::*/gmd:organisationName">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:if>

        <xsl:if test="ancestor-or-self::*/gmd:individualName">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>
    <!-- 06. Publisher element. Recommended. Repeatable -->
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'publisher']">
      <xsl:text>"dct_publisher_sm": [</xsl:text>
      <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'publisher']">
        <xsl:if test="ancestor-or-self::*/gmd:organisationName">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:if test="ancestor-or-self::*/gmd:individualName">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>
    <!-- 07. Provider element. Recommended. Not Repeatable. See notes for institution variable -->
    <xsl:if test="$institution">
      <xsl:text>"schema_provider_s": "</xsl:text>
      <xsl:value-of select="$institution"/>
      <xsl:text>",</xsl:text>
    </xsl:if>
    <!-- 08. Resource Class element. Required. Repeatable up to 5 times.  -->
      <xsl:text>"gbl_resourceClass_sm": [</xsl:text>
     <xsl:choose>
       <xsl:when test="gmd:MD_Metadata/gmd:hierarchyLevel/gmd:MD_ScopeCode[matches(@codeListValue, '[d|D]ataset$')] or gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:presentationForm/gmd:CI_PresentationFormCode[matches(@codeListValue, '^map')]">
         <xsl:for-each select="//*[@codeListValue[matches(self::node(), '[d|D]ataset$') or matches(self::node(), '^map')] and @codeListValue[ancestor::gmd:hierarchyLevel or ancestor::gmd:identificationInfo]]">
           <xsl:if test="self::node()[matches(@codeListValue, '[d|D]ataset$') and ancestor::gmd:hierarchyLevel]">
             <xsl:text>"Datasets"</xsl:text>
             <xsl:if test="position() != last()">
               <xsl:text>,</xsl:text>
             </xsl:if>
           </xsl:if>
           <xsl:if test="self::node()[matches(@codeListValue, '^map') and ancestor::gmd:identificationInfo]">
             <xsl:text>"Maps"</xsl:text>
             <xsl:if test="position() != last()">
               <xsl:text>,</xsl:text>
             </xsl:if>
           </xsl:if>
         </xsl:for-each>
       </xsl:when>
       <xsl:otherwise>
         <xsl:text>"Other"</xsl:text>
       </xsl:otherwise>
     </xsl:choose>
    <xsl:text>],</xsl:text>
    <!-- 09. Future site of Resource Type element. Recommended. Repeatable -->
    <!-- 10. Future site of Subject element. Optional. Repeatable -->
    <!-- 11. Future site of Theme element. Optional. Repeatable -->
    <!-- 12. Future site of Keyword element. Optional. Repeatable -->
    <!-- 13. Future site of Temporal Coverage element. Recommended. Repeatable -->
    <!-- 14. Future site of Date Issued element. Optional. Not Repeatable -->
    <!-- 15. Future site of Index Year element. Recommended. Repeatable -->
    <!-- 16. Future site of Date Range element. Optional. Repeatable -->
    <!-- 17. Future site of Spatial Coverage element. Recommended. Repeatable -->
    <!-- 18. Future site of Geometry element. Recommended. Not Repeatable -->
    <!-- 19. Future site of Bounding Box element. Recommended. Not Repeatable -->
    <!-- 20. Future site of Centroid element. Optional. Not Repeatable -->
    <!-- 21. Future site of Relation element. Optional. Repeatable -->
    <!-- 22. Future site of Member Of element. Optional. Repeatable -->
    <!-- 23. Future site of Is Part Of element. Optional. Repeatable -->
    <!-- 24. Future site of Source element. Optional. Repeatable -->
    <!-- 25. Future site of Is Version Of element. Optional. Repeatable -->
    <!-- 26. Future site of Replaceselement. Optional. Repeatable -->
    <!-- 27. Future site of Is Replaced By element. Optional. Repeatable -->
    <!-- 28. Rights element. Recommended. Not Repeatable. I'm going to leave this in here, but I don't actually think this is the right field. What comes up, at least from the ones I've done, is more of a legal disclaimer. -->
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useLimitation/gco:CharacterString">
      <xsl:text>"dct_rights_sm": [</xsl:text>
      <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints//gco:CharacterString">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="replace(text(), '\n', '&lt;br/&gt;')"/>
        <xsl:text>"</xsl:text>
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>
    <!-- 29. Future site of Rights Holder element. Optional. Repeatable -->
    <!-- 30. Future site of License element. Optional. Repeatable -->
    <!-- 31. Access Rights element. Required. Not Repeatable -->
    <xsl:text>"dct_accessRights_s": "</xsl:text>
    <xsl:choose>
      <xsl:when test="matches(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints/gco:CharacterString, '^Restricted to distribution to UW-System students, faculty, or staff for educational use')">
        <xsl:text>Restricted</xsl:text>
      </xsl:when>
      <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useConstraints/gmd:accessConstraints[@codeListValue='restricted']">
        <xsl:text>Restricted</xsl:text>
      </xsl:when>
      <!--<xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:accessConstraints/gmd:MD_RestrictionCode, 'restricted')">
        <xsl:text>Restricted</xsl:text>
      </xsl:when>
      <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useConstraints/gmd:MD_RestrictionCode[@codeListValue='restricted']">
        <xsl:text>Restricted</xsl:text>
      </xsl:when>
      <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useConstraints/gmd:MD_RestrictionCode, 'restricted')">
        <xsl:text>Restricted</xsl:text>
      </xsl:when>
      <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints">
        <xsl:choose>
          <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, 'restricted')">
            <xsl:text>Restricted</xsl:text>
          </xsl:when>
          <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, 'public domain')">
            <xsl:text>Public</xsl:text>
          </xsl:when>
          <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, $institution)">
            <xsl:text>Restricted</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>-->
      <xsl:otherwise>
        <xsl:text>Public</xsl:text>
      </xsl:otherwise>
    </xsl:choose><xsl:text>",</xsl:text>
    <xsl:text>"gbl_mdVersion_s": "Aardvark",</xsl:text>
    <xsl:text>"id": "</xsl:text>
    <xsl:value-of select="$uuid"/>
    <xsl:text>",</xsl:text>

    <xsl:text>"layer_id_s": "</xsl:text>
    <xsl:choose>
      <xsl:when test="$institution = 'Stanford'">
        <xsl:text>druid:</xsl:text>
        <xsl:value-of select="$identifier"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>urn:</xsl:text>
        <xsl:value-of select="$identifier"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>",</xsl:text>
    <xsl:text>"layer_geom_type_s": "</xsl:text>
    <xsl:choose>
      <xsl:when
        test="gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode[@codeListValue = 'surface']">
        <xsl:text>Polygon</xsl:text>
      </xsl:when>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode, 'surface')">
        <xsl:text>Polygon</xsl:text>
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode[@codeListValue = 'curve']">
        <xsl:text>Line</xsl:text>
      </xsl:when>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode, 'curve')">
        <xsl:text>Line</xsl:text>
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode[@codeListValue = 'point']">
        <xsl:text>Point</xsl:text>
      </xsl:when>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode, 'point')">
        <xsl:text>Point</xsl:text>
      </xsl:when>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode, 'grid')">
        <xsl:text>Raster</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:text>",</xsl:text>
    <xsl:text>"layer_slug_s": "</xsl:text>
    <xsl:value-of select="$institution"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="$identifier"/>
    <xsl:text>","gbl_mdModified_dt": "</xsl:text>
    <xsl:value-of select="adjust-dateTime-to-timezone(current-dateTime(),xs:dayTimeDuration('PT0H'))"/>
        <xsl:text>",</xsl:text>


        <xsl:text>"dc_format_s": "</xsl:text>
    <xsl:value-of select="$format"/>
    <xsl:text>",</xsl:text>

    <!-- TODO: add inputs for other languages -->
    <!-- <field name="dc_language_s">
          <xsl:if test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language | gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language/gmd:LanguageCode, 'eng')">
            <xsl:text>English</xsl:text>
          </xsl:if>
        </field> -->

    <!-- from DCMI type vocabulary -->

    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode">
      <xsl:text>"dc_subject_sm": [</xsl:text>
      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>"</xsl:text>
        <xsl:text>,</xsl:text>
      </xsl:for-each>

      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords[descendant::gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'theme']]">
        <xsl:for-each select="gmd:keyword">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>],</xsl:text>

    </xsl:if>

    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'place']">
      <xsl:text>"dc_spatial_sm": [</xsl:text>
      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'place']">
        <xsl:for-each select="ancestor-or-self::*/gmd:keyword">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>

    <xsl:choose>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 'T')">
        <xsl:text>"dct_issued_s": "</xsl:text>
        <xsl:value-of
          select="substring-before(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 'T')"/>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
        <xsl:text>"dct_issued_s": "</xsl:text>
        <xsl:value-of
          select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
        <xsl:text>"dct_issued_s": "</xsl:text>
        <xsl:value-of
          select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"/>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <!-- <xsl:otherwise>unknown</xsl:otherwise> -->
    </xsl:choose>


    <!-- content date: range YYYY-YYYY if dates differ  -->
    <xsl:choose>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition/text() != ''">
        <xsl:text>"dct_temporal_sm": "</xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
        <xsl:if
          test="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 1, 4) != substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1, 4)">
          <xsl:text>-</xsl:text>
          <xsl:value-of
            select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 1, 4)"
          />
        </xsl:if>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant">
        <xsl:text>"dct_temporal_sm": "</xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant, 1, 4)"/>
        <xsl:text>",</xsl:text>
      </xsl:when>
    </xsl:choose>

    <!-- collection -->
    <!-- <xsl:choose>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='largerWorkCitation']">
            <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='largerWorkCitation']">
            <field name="dct_isPartOf_sm">
              <xsl:value-of select="ancestor-or-self::*/gmd:aggregateDataSetName/gmd:CI_Citation/gmd:title"/>
           </field>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:collectiveTitle">
            <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:collectiveTitle">
            <field name="dct_isPartOf_sm">
              <xsl:value-of select="."/>
            </field>
            </xsl:for-each>
          </xsl:when>
        </xsl:choose> -->

    <xsl:text>"solr_geom": "ENVELOPE(</xsl:text>
    <xsl:value-of select="$x1"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$x2"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$y2"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$y1"/>
    <xsl:text>)",</xsl:text>

    <!-- content date: singular, or beginning date of range: YYYY -->
    <xsl:choose>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition/text() != ''">
        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1, 4)"
        />
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant">
        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant, 1, 4)"
        />
      </xsl:when>
    </xsl:choose>
    <xsl:text>}</xsl:text>
  </xsl:template>

</xsl:stylesheet>