<xsl:stylesheet xmlns="http://www.loc.gov/mods/v3" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="xlink marc" version="1.0">
	<xsl:include href="http://www.loc.gov/standards/marcxml/xslt/MARC21slimUtils.xsl"/>
	<xsl:output encoding="UTF-8" indent="yes" method="xml"/>
	<xsl:strip-space elements="*"/>

	<!-- Maintenance note: For each revision, change the content of <recordInfo><recordOrigin> to reflect the new revision number.
	MARC21slim2MODS3-5 (Revision 1.106) 20141219
	
Revision 1.106 - Added a xsl:when to deal with '#' and ' ' in $leader19 and $controlField008-18 - ws 2014/12/19		
Revision 1.105 - Add @unit to extent - ws 2014/11/20	
Revision 1.104 - Fixed 111$n and 711$n to reflect mapping to <namePart> tmee 20141112
Revision 1.103 - Fixed 008/28 to reflect revised mapping for government publication tmee 20141104	
Revision 1.102 - Fixed 240$s duplication tmee 20140812
Revision 1.101 - Fixed 130 tmee 20140806
Revision 1.100 - Fixed 245c tmee 20140804
Revision 1.99 - Fixed 240 issue tmee 20140804
Revision 1.98 - Fixed 336 mapping tmee 20140522
Revision 1.97 - Fixed 264 mapping tmee 20140521
Revision 1.96 - Fixed 310 and 321 and 008 frequency authority for marcfrequency tmee 2014/04/22
Revision 1.95 - Modified 035 to include identifier type (WlCaITV) tmee 2014/04/21	
Revision 1.94 - Leader 07 b changed mapping from continuing to serial tmee 2014/02/21
MODS 3.5 
Revision 1.93 - Fixed personal name transform for ind1=0 tmee 2014/01/31
Revision 1.92 - Removed duplicate code for 856 1.51 tmee 2014/01/31
Revision 1.91 - Fixed createnameFrom720 duplication tmee 2014/01/31
Revision 1.90 - Fixed 520 displayLabel tmee tmee 2014/01/31
Revision 1.89 - Fixed 008-06 when value = 's' for cartographics tmee tmee 2014/01/31
Revision 1.88 - Fixed 510c mapping - tmee 2013/08/29
Revision 1.87 - Fixed expressions of <accessCondition> type values - tmee 2013/08/29
Revision 1.86 - Fixed 008 <frequency> subfield to occur w/i <originiInfo> - tmee 2013/08/29
Revision 1.85 - Fixed 245$c - tmee 2013/03/07
Revision 1.84 - Fixed 1.35 and 1.36 date mapping for 008 when 008/06=e,p,r,s,t so only 008/07-10 displays, rather than 008/07-14 - tmee 2013/02/01   
Revision 1.83 - Deleted mapping for 534 to note - tmee 2013/01/18
Revision 1.82 - Added mapping for 264 ind 0,1,2,3 to originInfo - 2013/01/15 tmee
Revision 1.81 - Added mapping for 336$a$2, 337$a$2, 338$a$2 - 2012/12/03 tmee
Revision 1.80 - Added 100/700 mapping for "family" - 2012/09/10 tmee
Revision 1.79 - Added 245 $s mapping - 2012/07/11 tmee
Revision 1.78 - Fixed 852 mapping <shelfLocation> was changed to <shelfLocator> - 2012/05/07 tmee
Revision 1.77 - Fixed 008-06 when value = 's' - 2012/04/19 tmee
Revision 1.76 - Fixed 242 - 2012/02/01 tmee
Revision 1.75 - Fixed 653 - 2012/01/31 tmee
Revision 1.74 - Fixed 510 note - 2011/07/15 tmee
Revision 1.73 - Fixed 506 540 - 2011/07/11 tmee
Revision 1.72 - Fixed frequency error - 2011/07/07 and 2011/07/14 tmee
Revision 1.71 - Fixed subject titles for subfields t - 2011/04/26 tmee 
Revision 1.70 - Added mapping for OCLC numbers in 035s to go into <identifier type="oclc"> 2011/02/27 - tmee 	
Revision 1.69 - Added mapping for untyped identifiers for 024 - 2011/02/27 tmee 
Revision 1.68 - Added <subject><titleInfo> mapping for 600/610/611 subfields t,p,n - 2010/12/22 tmee
Revision 1.67 - Added frequency values and authority="marcfrequency" for 008/18 - 2010/12/09 tmee
Revision 1.66 - Fixed 008/06=c,d,i,m,k,u, from dateCreated to dateIssued - 2010/12/06 tmee
Revision 1.65 - Added back marcsmd and marccategory for 007 cr- 2010/12/06 tmee
Revision 1.64 - Fixed identifiers - removed isInvalid template - 2010/12/06 tmee
Revision 1.63 - Fixed descriptiveStandard value from aacr2 to aacr - 2010/12/06 tmee
Revision 1.62 - Fixed date mapping for 008/06=e,p,r,s,t - 2010/12/01 tmee
Revision 1.61 - Added 007 mappings for marccategory - 2010/11/12 tmee
Revision 1.60 - Added altRepGroups and 880 linkages for relevant fields, see mapping - 2010/11/26 tmee
Revision 1.59 - Added scriptTerm type=text to language for 546b and 066c - 2010/09/23 tmee
Revision 1.58 - Expanded script template to include code conversions for extended scripts - 2010/09/22 tmee
Revision 1.57 - Added Ldr/07 and Ldr/19 mappings - 2010/09/17 tmee
Revision 1.56 - Mapped 1xx usage="primary" - 2010/09/17 tmee
Revision 1.55 - Mapped UT 240/1xx nameTitleGroup - 2010/09/17 tmee
MODS 3.4
Revision 1.54 - Fixed 086 redundancy - 2010/07/27 tmee
Revision 1.53 - Added direct href for MARC21slimUtils - 2010/07/27 tmee
Revision 1.52 - Mapped 046 subfields c,e,k,l - 2010/04/09 tmee
Revision 1.51 - Corrected 856 transform - 2010/01/29 tmee
Revision 1.50 - Added 210 $2 authority attribute in <titleInfo type=”abbreviated”> 2009/11/23 tmee
Revision 1.49 - Aquifer revision 1.14 - Added 240s (version) data to <titleInfo type="uniform"><title> 2009/11/23 tmee
Revision 1.48 - Aquifer revision 1.27 - Added mapping of 242 second indicator (for nonfiling characters) to <titleInfo><nonSort > subelement  2007/08/08 tmee/dlf
Revision 1.47 - Aquifer revision 1.26 - Mapped 300 subfield f (type of unit) - and g (size of unit) 2009 ntra
Revision 1.46 - Aquifer revision 1.25 - Changed mapping of 767 so that <type="otherVersion>  2009/11/20  tmee
Revision 1.45 - Aquifer revision 1.24 - Changed mapping of 765 so that <type="otherVersion>  2009/11/20  tmee 
Revision 1.44 - Added <recordInfo><recordOrigin> canned text about the version of this stylesheet 2009 ntra
Revision 1.43 - Mapped 351 subfields a,b,c 2009/11/20 tmee
Revision 1.42 - Changed 856 second indicator=1 to go to <location><url displayLabel=”electronic resource”> instead of to <relatedItem type=”otherVersion”><url> 2009/11/20 tmee
Revision 1.41 - Aquifer revision 1.9 Added variable and choice protocol for adding usage=”primary display” 2009/11/19 tmee 
Revision 1.40 - Dropped <note> for 510 and added <relatedItem type="isReferencedBy"> for 510 2009/11/19 tmee
Revision 1.39 - Aquifer revision 1.23 Changed mapping for 762 (Subseries Entry) from <relatedItem type="series"> to <relatedItem type="constituent"> 2009/11/19 tmee
Revision 1.38 - Aquifer revision 1.29 Dropped 007s for electronic versions 2009/11/18 tmee
Revision 1.37 - Fixed date redundancy in output (with questionable dates) 2009/11/16 tmee
Revision 1.36 - If mss material (Ldr/06=d,p,f,t) map 008 dates and 260$c/$g dates to dateCreated 2009/11/24, otherwise map 008 and 260$c/$g to dateIssued 2010/01/08 tmee
Revision 1.35 - Mapped appended detailed dates from 008/07-10 and 008/11-14 to dateIssued or DateCreated w/encoding="marc" 2010/01/12 tmee
Revision 1.34 - Mapped 045b B.C. and C.E. date range info to iso8601-compliant dates in <subject><temporal> 2009/01/08 ntra
Revision 1.33 - Mapped Ldr/06 "o" to <typeOfResource>kit 2009/11/16 tmee
Revision 1.32 - Mapped specific note types from the MODS Note Type list <http://www.loc.gov/standards/mods/mods-notes.html> tmee 2009/11/17
Revision 1.31 - Mapped 540 to <accessCondition type="use and reproduction"> and 506 to <accessCondition type="restriction on access"> and delete mappings of 540 and 506 to <note>
Revision 1.30 - Mapped 037c to <identifier displayLabel=""> 2009/11/13 tmee
Revision 1.29 - Corrected schemaLocation to 3.3 2009/11/13 tmee
Revision 1.28 - Changed mapping from 752,662 g going to mods:hierarchicalGeographic/area instead of "region" 2009/07/30 ntra
Revision 1.27 - Mapped 648 to <subject> 2009/03/13 tmee
Revision 1.26 - Added subfield $s mapping for 130/240/730  2008/10/16 tmee
Revision 1.25 - Mapped 040e to <descriptiveStandard> and Leader/18 to <descriptive standard>aacr2  2008/09/18 tmee
Revision 1.24 - Mapped 852 subfields $h, $i, $j, $k, $l, $m, $t to <shelfLocation> and 852 subfield $u to <physicalLocation> with @xlink 2008/09/17 tmee
Revision 1.23 - Commented out xlink/uri for subfield 0 for 130/240/730, 100/700, 110/710, 111/711 as these are currently unactionable  2008/09/17 tmee
Revision 1.22 - Mapped 022 subfield $l to type "issn-l" subfield $m to output identifier element with corresponding @type and @invalid eq 'yes'2008/09/17 tmee
Revision 1.21 - Mapped 856 ind2=1 or ind2=2 to <relatedItem><location><url>  2008/07/03 tmee
Revision 1.20 - Added genre w/@auth="contents of 2" and type= "musical composition"  2008/07/01 tmee
Revision 1.19 - Added genre offprint for 008/24+ BK code 2  2008/07/01  tmee
Revision 1.18 - Added xlink/uri for subfield 0 for 130/240/730, 100/700, 110/710, 111/711  2008/06/26 tmee
Revision 1.17 - Added mapping of 662 2008/05/14 tmee	
Revision 1.16 - Changed @authority from "marc" to "marcgt" for 007 and 008 codes mapped to a term in <genre> 2007/07/10 tmee
Revision 1.15 - For field 630, moved call to part template outside title element  2007/07/10 tmee
Revision 1.14 - Fixed template isValid and fields 010, 020, 022, 024, 028, and 037 to output additional identifier elements with corresponding @type and @invalid eq 'yes' when subfields z or y (in the case of 022) exist in the MARCXML ::: 2007/01/04 17:35:20 cred
Revision 1.13 - Changed order of output under cartographics to reflect schema  2006/11/28 tmee
Revision 1.12 - Updated to reflect MODS 3.2 Mapping  2006/10/11 tmee
Revision 1.11 - The attribute objectPart moved from <languageTerm> to <language>  2006/04/08  jrad
Revision 1.10 - MODS 3.1 revisions to language and classification elements (plus ability to find marc:collection embedded in wrapper elements such as SRU zs: wrappers)  2006/02/06  ggar
Revision 1.09 - Subfield $y was added to field 242 2004/09/02 10:57 jrad
Revision 1.08 - Subject chopPunctuation expanded and attribute fixes 2004/08/12 jrad
Revision 1.07 - 2004/03/25 08:29 jrad
Revision 1.06 - Various validation fixes 2004/02/20 ntra
Revision 1.05 - MODS2 to MODS3 updates, language unstacking and de-duping, chopPunctuation expanded  2003/10/02 16:18:58  ntra
Revision 1.03 - Additional Changes not related to MODS Version 2.0 by ntra
Revision 1.02 - Added Log Comment  2003/03/24 19:37:42  ckeith
	-->

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="//marc:collection">
				<modsCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
					<xsl:for-each select="//marc:collection/marc:record">
						<mods version="3.5">
							<xsl:call-template name="marcRecord"/>
						</mods>
					</xsl:for-each>
				</modsCollection>
			</xsl:when>
			<xsl:otherwise>
				<mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
					<xsl:for-each select="//marc:record">
						<xsl:call-template name="marcRecord"/>
					</xsl:for-each>
				</mods>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="marcRecord">
		<xsl:variable name="leader" select="marc:leader"/>
		<xsl:variable name="leader6" select="substring($leader,7,1)"/>
		<xsl:variable name="leader7" select="substring($leader,8,1)"/>
		<xsl:variable name="leader19" select="substring($leader,20,1)"/>
		<xsl:variable name="controlField008" select="marc:controlfield[@tag='008']"/>
		<xsl:variable name="typeOf008">
			<xsl:choose>
				<xsl:when test="$leader6='a'">
					<xsl:choose>
						<xsl:when test="$leader7='a' or $leader7='c' or $leader7='d' or $leader7='m'">BK</xsl:when>
						<xsl:when test="$leader7='b' or $leader7='i' or $leader7='s'">SE</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$leader6='t'">BK</xsl:when>
				<xsl:when test="$leader6='p'">MM</xsl:when>
				<xsl:when test="$leader6='m'">CF</xsl:when>
				<xsl:when test="$leader6='e' or $leader6='f'">MP</xsl:when>
				<xsl:when test="$leader6='g' or $leader6='k' or $leader6='o' or $leader6='r'">VM</xsl:when>
				<xsl:when test="$leader6='c' or $leader6='d' or $leader6='i' or $leader6='j'">MU</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<!-- titleInfo -->

		<xsl:for-each select="marc:datafield[@tag='245']">
			<xsl:call-template name="createTitleInfoFrom245"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='210']">
			<xsl:call-template name="createTitleInfoFrom210"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='246']">
			<xsl:call-template name="createTitleInfoFrom246"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='240']">
			<xsl:call-template name="createTitleInfoFrom240"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='740']">
			<xsl:call-template name="createTitleInfoFrom740"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='130']">
			<xsl:call-template name="createTitleInfoFrom130"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='730']">
			<xsl:call-template name="createTitleInfoFrom730"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='242']">
			<titleInfo type="translated">
				<!--09/01/04 Added subfield $y-->
				<xsl:for-each select="marc:subfield[@code='y']">
					<xsl:attribute name="lang">
						<xsl:value-of select="text()"/>
					</xsl:attribute>
				</xsl:for-each>

				<!-- AQ1.27 tmee/dlf -->
				<xsl:variable name="title">
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<!-- 1/04 removed $h, b -->
								<xsl:with-param name="codes">a</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="titleChop">
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="$title"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="@ind2&gt;0">
						<nonSort>
							<xsl:value-of select="substring($titleChop,1,@ind2)"/>
						</nonSort>
						<title>
							<xsl:value-of select="substring($titleChop,@ind2+1)"/>
						</title>
					</xsl:when>
					<xsl:otherwise>
						<title>
							<xsl:value-of select="$titleChop"/>
						</title>
					</xsl:otherwise>
				</xsl:choose>

				<!-- 1/04 fix -->
				<xsl:call-template name="subtitle"/>
				<xsl:call-template name="part"/>
			</titleInfo>
		</xsl:for-each>

		<!-- name -->

		<xsl:for-each select="marc:datafield[@tag='100']">
			<xsl:call-template name="createNameFrom100"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='110']">
			<xsl:call-template name="createNameFrom110"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='111']">
			<xsl:call-template name="createNameFrom111"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='700']">
			<xsl:call-template name="createNameFrom700"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='710']">
			<xsl:call-template name="createNameFrom710"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='711']">
			<xsl:call-template name="createNameFrom711"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='720']">
			<xsl:call-template name="createNameFrom720"/>
		</xsl:for-each>

		<!--old 7XXs
		<xsl:for-each select="marc:datafield[@tag='700'][not(marc:subfield[@code='t'])]">
			<name type="personal">
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='710'][not(marc:subfield[@code='t'])]">
			<name type="corporate">
				<xsl:call-template name="nameABCDN"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='711'][not(marc:subfield[@code='t'])]">
			<name type="conference">
				<xsl:call-template name="nameACDEQ"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag='720'][not(marc:subfield[@code='t'])]">
		<name>
		<xsl:if test="@ind1=1">
		<xsl:attribute name="type">
		<xsl:text>personal</xsl:text>
		</xsl:attribute>
		</xsl:if>
		<namePart>
		<xsl:value-of select="marc:subfield[@code='a']"/>
		</namePart>
		<xsl:call-template name="role"/>
		</name>
		</xsl:for-each>
-->

		<typeOfResource>
			<xsl:if test="$leader7='c'">
				<xsl:attribute name="collection">yes</xsl:attribute>
			</xsl:if>
			<xsl:if test="$leader6='d' or $leader6='f' or $leader6='p' or $leader6='t'">
				<xsl:attribute name="manuscript">yes</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="$leader6='a' or $leader6='t'">text</xsl:when>
				<xsl:when test="$leader6='e' or $leader6='f'">cartographic</xsl:when>
				<xsl:when test="$leader6='c' or $leader6='d'">notated music</xsl:when>
				<xsl:when test="$leader6='i'">sound recording-nonmusical</xsl:when>
				<xsl:when test="$leader6='j'">sound recording-musical</xsl:when>
				<xsl:when test="$leader6='k'">still image</xsl:when>
				<xsl:when test="$leader6='g'">moving image</xsl:when>
				<xsl:when test="$leader6='r'">three dimensional object</xsl:when>
				<xsl:when test="$leader6='m'">software, multimedia</xsl:when>
				<xsl:when test="$leader6='p'">mixed material</xsl:when>
			</xsl:choose>
		</typeOfResource>
		<xsl:if test="substring($controlField008,26,1)='d'">
			<genre authority="marcgt">globe</genre>
		</xsl:if>
		<xsl:if test="marc:controlfield[@tag='007'][substring(text(),1,1)='a'][substring(text(),2,1)='r']">
			<genre authority="marcgt">remote-sensing image</genre>
		</xsl:if>
		<xsl:if test="$typeOf008='MP'">
			<xsl:variable name="controlField008-25" select="substring($controlField008,26,1)"/>
			<xsl:choose>
				<xsl:when test="$controlField008-25='a' or $controlField008-25='b' or $controlField008-25='c' or marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='j']">
					<genre authority="marcgt">map</genre>
				</xsl:when>
				<xsl:when test="$controlField008-25='e' or marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='d']">
					<genre authority="marcgt">atlas</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='SE'">
			<xsl:variable name="controlField008-21" select="substring($controlField008,22,1)"/>
			<xsl:choose>
				<xsl:when test="$controlField008-21='d'">
					<genre authority="marcgt">database</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='l'">
					<genre authority="marcgt">loose-leaf</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='m'">
					<genre authority="marcgt">series</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='n'">
					<genre authority="marcgt">newspaper</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='p'">
					<genre authority="marcgt">periodical</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='w'">
					<genre authority="marcgt">web site</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='BK' or $typeOf008='SE'">
			<xsl:variable name="controlField008-24" select="substring($controlField008,25,4)"/>
			<xsl:choose>
				<xsl:when test="contains($controlField008-24,'a')">
					<genre authority="marcgt">abstract or summary</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'b')">
					<genre authority="marcgt">bibliography</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'c')">
					<genre authority="marcgt">catalog</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'d')">
					<genre authority="marcgt">dictionary</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'e')">
					<genre authority="marcgt">encyclopedia</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'f')">
					<genre authority="marcgt">handbook</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'g')">
					<genre authority="marcgt">legal article</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'i')">
					<genre authority="marcgt">index</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'k')">
					<genre authority="marcgt">discography</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'l')">
					<genre authority="marcgt">legislation</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'m')">
					<genre authority="marcgt">theses</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'n')">
					<genre authority="marcgt">survey of literature</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'o')">
					<genre authority="marcgt">review</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'p')">
					<genre authority="marcgt">programmed text</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'q')">
					<genre authority="marcgt">filmography</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'r')">
					<genre authority="marcgt">directory</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'s')">
					<genre authority="marcgt">statistics</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'t')">
					<genre authority="marcgt">technical report</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'v')">
					<genre authority="marcgt">legal case and case notes</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'w')">
					<genre authority="marcgt">law report or digest</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'z')">
					<genre authority="marcgt">treaty</genre>
				</xsl:when>
			</xsl:choose>
			<xsl:variable name="controlField008-29" select="substring($controlField008,30,1)"/>
			<xsl:choose>
				<xsl:when test="$controlField008-29='1'">
					<genre authority="marcgt">conference publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='CF'">
			<xsl:variable name="controlField008-26" select="substring($controlField008,27,1)"/>
			<xsl:choose>
				<xsl:when test="$controlField008-26='a'">
					<genre authority="marcgt">numeric data</genre>
				</xsl:when>
				<xsl:when test="$controlField008-26='e'">
					<genre authority="marcgt">database</genre>
				</xsl:when>
				<xsl:when test="$controlField008-26='f'">
					<genre authority="marcgt">font</genre>
				</xsl:when>
				<xsl:when test="$controlField008-26='g'">
					<genre authority="marcgt">game</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='BK'">
			<xsl:if test="substring($controlField008,25,1)='j'">
				<genre authority="marcgt">patent</genre>
			</xsl:if>
			<xsl:if test="substring($controlField008,25,1)='2'">
				<genre authority="marcgt">offprint</genre>
			</xsl:if>
			<xsl:if test="substring($controlField008,31,1)='1'">
				<genre authority="marcgt">festschrift</genre>
			</xsl:if>
			<xsl:variable name="controlField008-34" select="substring($controlField008,35,1)"/>
			<xsl:if test="$controlField008-34='a' or $controlField008-34='b' or $controlField008-34='c' or $controlField008-34='d'">
				<genre authority="marcgt">biography</genre>
			</xsl:if>
			<xsl:variable name="controlField008-33" select="substring($controlField008,34,1)"/>
			<xsl:choose>
				<xsl:when test="$controlField008-33='e'">
					<genre authority="marcgt">essay</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='d'">
					<genre authority="marcgt">drama</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='c'">
					<genre authority="marcgt">comic strip</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='l'">
					<genre authority="marcgt">fiction</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='h'">
					<genre authority="marcgt">humor, satire</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='i'">
					<genre authority="marcgt">letter</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='f'">
					<genre authority="marcgt">novel</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='j'">
					<genre authority="marcgt">short story</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='s'">
					<genre authority="marcgt">speech</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='MU'">
			<xsl:variable name="controlField008-30-31" select="substring($controlField008,31,2)"/>
			<xsl:if test="contains($controlField008-30-31,'b')">
				<genre authority="marcgt">biography</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'c')">
				<genre authority="marcgt">conference publication</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'d')">
				<genre authority="marcgt">drama</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'e')">
				<genre authority="marcgt">essay</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'f')">
				<genre authority="marcgt">fiction</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'o')">
				<genre authority="marcgt">folktale</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'h')">
				<genre authority="marcgt">history</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'k')">
				<genre authority="marcgt">humor, satire</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'m')">
				<genre authority="marcgt">memoir</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'p')">
				<genre authority="marcgt">poetry</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'r')">
				<genre authority="marcgt">rehearsal</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'g')">
				<genre authority="marcgt">reporting</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'s')">
				<genre authority="marcgt">sound</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'l')">
				<genre authority="marcgt">speech</genre>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$typeOf008='VM'">
			<xsl:variable name="controlField008-33" select="substring($controlField008,34,1)"/>
			<xsl:choose>
				<xsl:when test="$controlField008-33='a'">
					<genre authority="marcgt">art original</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='b'">
					<genre authority="marcgt">kit</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='c'">
					<genre authority="marcgt">art reproduction</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='d'">
					<genre authority="marcgt">diorama</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='f'">
					<genre authority="marcgt">filmstrip</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='g'">
					<genre authority="marcgt">legal article</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='i'">
					<genre authority="marcgt">picture</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='k'">
					<genre authority="marcgt">graphic</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='l'">
					<genre authority="marcgt">technical drawing</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='m'">
					<genre authority="marcgt">motion picture</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='n'">
					<genre authority="marcgt">chart</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='o'">
					<genre authority="marcgt">flash card</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='p'">
					<genre authority="marcgt">microscope slide</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='q' or marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='q']">
					<genre authority="marcgt">model</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='r'">
					<genre authority="marcgt">realia</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='s'">
					<genre authority="marcgt">slide</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='t'">
					<genre authority="marcgt">transparency</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='v'">
					<genre authority="marcgt">videorecording</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='w'">
					<genre authority="marcgt">toy</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
	
<!-- 111$n, 711$n 1.103 -->	
		
		<xsl:if test="$typeOf008='BK'">
			<xsl:variable name="controlField008-28" select="substring($controlField008,29,1)"/>
			<xsl:choose>
				<xsl:when test="contains($controlField008-28,'a')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'c')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'f')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'i')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'l')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'o')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'s')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'u')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'z')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'|')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='CF'">
			<xsl:variable name="controlField008-28" select="substring($controlField008,29,1)"/>
			<xsl:choose>
				<xsl:when test="contains($controlField008-28,'a')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'c')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'f')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'i')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'l')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'o')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'s')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'u')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'z')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'|')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='CR'">
			<xsl:variable name="controlField008-28" select="substring($controlField008,29,1)"/>
			<xsl:choose>
				<xsl:when test="contains($controlField008-28,'a')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'c')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'f')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'i')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'l')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'o')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'s')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'u')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'z')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'|')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='MP'">
			<xsl:variable name="controlField008-28" select="substring($controlField008,29,1)"/>
			<xsl:choose>
				<xsl:when test="contains($controlField008-28,'a')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'c')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'f')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'i')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'l')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'o')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'s')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'u')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'z')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'|')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='VM'">
			<xsl:variable name="controlField008-28" select="substring($controlField008,29,1)"/>
			<xsl:choose>
				<xsl:when test="contains($controlField008-28,'a')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'c')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'f')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'i')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'l')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'m')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'o')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'s')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'u')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'z')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-28,'|')">
					<genre authority="marcgt">government publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		

		<!-- genre -->

		<xsl:for-each select="marc:datafield[@tag=047]">
			<xsl:call-template name="createGenreFrom047"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=336]">
			<xsl:call-template name="createGenreFrom336"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=655]">
			<xsl:call-template name="createGenreFrom655"/>
		</xsl:for-each>

		<!-- originInfo 250 and 260 -->

		<originInfo>
			<xsl:call-template name="scriptCode"/>
			<xsl:for-each select="marc:datafield[(@tag=260 or @tag=250) and marc:subfield[@code='a' or code='b' or @code='c' or code='g']]">
				<xsl:call-template name="z2xx880"/>
			</xsl:for-each>

			<xsl:variable name="MARCpublicationCode" select="normalize-space(substring($controlField008,16,3))"/>
			<xsl:if test="translate($MARCpublicationCode,'|','')">
				<place>
					<placeTerm>
						<xsl:attribute name="type">code</xsl:attribute>
						<xsl:attribute name="authority">marccountry</xsl:attribute>
						<xsl:value-of select="$MARCpublicationCode"/>
					</placeTerm>
				</place>
			</xsl:if>
			<xsl:for-each select="marc:datafield[@tag=044]/marc:subfield[@code='c']">
				<place>
					<placeTerm>
						<xsl:attribute name="type">code</xsl:attribute>
						<xsl:attribute name="authority">iso3166</xsl:attribute>
						<xsl:value-of select="."/>
					</placeTerm>
				</place>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=260]/marc:subfield[@code='a']">
				<place>
					<placeTerm>
						<xsl:attribute name="type">text</xsl:attribute>
						<xsl:call-template name="chopPunctuationFront">
							<xsl:with-param name="chopString">
								<xsl:call-template name="chopPunctuation">
									<xsl:with-param name="chopString" select="."/>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</placeTerm>
				</place>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='m']">
				<dateValid point="start">
					<xsl:value-of select="."/>
				</dateValid>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='n']">
				<dateValid point="end">
					<xsl:value-of select="."/>
				</dateValid>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='j']">
				<dateModified>
					<xsl:value-of select="."/>
				</dateModified>
			</xsl:for-each>

			<!-- tmee 1.52 -->

			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='c']">
				<dateIssued encoding="marc" point="start">
					<xsl:value-of select="."/>
				</dateIssued>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='e']">
				<dateIssued encoding="marc" point="end">
					<xsl:value-of select="."/>
				</dateIssued>
			</xsl:for-each>

			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='k']">
				<dateCreated encoding="marc" point="start">
					<xsl:value-of select="."/>
				</dateCreated>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='l']">
				<dateCreated encoding="marc" point="end">
					<xsl:value-of select="."/>
				</dateCreated>
			</xsl:for-each>

			<!-- tmee 1.35 1.36 dateIssued/nonMSS vs dateCreated/MSS -->
			<xsl:for-each select="marc:datafield[@tag=260]/marc:subfield[@code='b' or @code='c' or @code='g']">
				<xsl:choose>
					<xsl:when test="@code='b'">
						<publisher>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."/>
								<xsl:with-param name="punctuation">
									<xsl:text>:,;/ </xsl:text>
								</xsl:with-param>
							</xsl:call-template>
						</publisher>
					</xsl:when>
					<xsl:when test="(@code='c')">
						<xsl:if test="$leader6='d' or $leader6='f' or $leader6='p' or $leader6='t'">
							<dateCreated>
								<xsl:call-template name="chopPunctuation">
									<xsl:with-param name="chopString" select="."/>
								</xsl:call-template>
							</dateCreated>
						</xsl:if>

						<xsl:if test="not($leader6='d' or $leader6='f' or $leader6='p' or $leader6='t')">
							<dateIssued>
								<xsl:call-template name="chopPunctuation">
									<xsl:with-param name="chopString" select="."/>
								</xsl:call-template>
							</dateIssued>
						</xsl:if>
					</xsl:when>
					<xsl:when test="@code='g'">
						<xsl:if test="$leader6='d' or $leader6='f' or $leader6='p' or $leader6='t'">
							<dateCreated>
								<xsl:value-of select="."/>
							</dateCreated>
						</xsl:if>
						<xsl:if test="not($leader6='d' or $leader6='f' or $leader6='p' or $leader6='t')">
							<dateCreated>
								<xsl:value-of select="."/>
							</dateCreated>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<xsl:variable name="dataField260c">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="marc:datafield[@tag=260]/marc:subfield[@code='c']"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="controlField008-7-10" select="normalize-space(substring($controlField008, 8, 4))"/>
			<xsl:variable name="controlField008-11-14" select="normalize-space(substring($controlField008, 12, 4))"/>
			<xsl:variable name="controlField008-6" select="normalize-space(substring($controlField008, 7, 1))"/>



			<!-- tmee 1.35 and 1.36 and 1.84-->

			<xsl:if test="($controlField008-6='e' or $controlField008-6='p' or $controlField008-6='r' or $controlField008-6='s' or $controlField008-6='t') and ($leader6='d' or $leader6='f' or $leader6='p' or $leader6='t')">
				<xsl:if test="$controlField008-7-10 and ($controlField008-7-10 != $dataField260c)">
					<dateCreated encoding="marc">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateCreated>
				</xsl:if>
			</xsl:if>

			<xsl:if test="($controlField008-6='e' or $controlField008-6='p' or $controlField008-6='r' or $controlField008-6='s' or $controlField008-6='t') and not($leader6='d' or $leader6='f' or $leader6='p' or $leader6='t')">
				<xsl:if test="$controlField008-7-10 and ($controlField008-7-10 != $dataField260c)">
					<dateIssued encoding="marc">
						<xsl:value-of select="$controlField008-7-10"/></dateIssued>
				</xsl:if>
			</xsl:if>

			<xsl:if test="$controlField008-6='c' or $controlField008-6='d' or $controlField008-6='i' or $controlField008-6='k' or $controlField008-6='m' or $controlField008-6='u'">
				<xsl:if test="$controlField008-7-10">
					<dateIssued encoding="marc" point="start">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>

			<xsl:if test="$controlField008-6='c' or $controlField008-6='d' or $controlField008-6='i' or $controlField008-6='k' or $controlField008-6='m' or $controlField008-6='u'">
				<xsl:if test="$controlField008-11-14">
					<dateIssued encoding="marc" point="end">
						<xsl:value-of select="$controlField008-11-14"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>

			<xsl:if test="$controlField008-6='q'">
				<xsl:if test="$controlField008-7-10">
					<dateIssued encoding="marc" point="start" qualifier="questionable">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$controlField008-6='q'">
				<xsl:if test="$controlField008-11-14">
					<dateIssued encoding="marc" point="end" qualifier="questionable">
						<xsl:value-of select="$controlField008-11-14"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>


			<!-- tmee 1.77 008-06 dateIssued for value 's' 1.89 removed 20130920 
			<xsl:if test="$controlField008-6='s'">
				<xsl:if test="$controlField008-7-10">
					<dateIssued encoding="marc">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			-->
			
			<xsl:if test="$controlField008-6='t'">
				<xsl:if test="$controlField008-11-14">
					<copyrightDate encoding="marc">
						<xsl:value-of select="$controlField008-11-14"/>
					</copyrightDate>
				</xsl:if>
			</xsl:if>
			<xsl:for-each select="marc:datafield[@tag=033][@ind1=0 or @ind1=1]/marc:subfield[@code='a']">
				<dateCaptured encoding="iso8601">
					<xsl:value-of select="."/>
				</dateCaptured>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=033][@ind1=2]/marc:subfield[@code='a'][1]">
				<dateCaptured encoding="iso8601" point="start">
					<xsl:value-of select="."/>
				</dateCaptured>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=033][@ind1=2]/marc:subfield[@code='a'][2]">
				<dateCaptured encoding="iso8601" point="end">
					<xsl:value-of select="."/>
				</dateCaptured>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=250]/marc:subfield[@code='a']">
				<edition>
					<xsl:value-of select="."/>
				</edition>
			</xsl:for-each>
			<xsl:for-each select="marc:leader">
				<issuance>
					<xsl:choose>
						<xsl:when test="$leader7='a' or $leader7='c' or $leader7='d' or $leader7='m'">monographic</xsl:when>
						<xsl:when test="$leader7='m' and ($leader19='a' or $leader19='b' or $leader19='c')">multipart monograph</xsl:when>
						<!-- 1.106 20141218 -->
						<xsl:when test="$leader7='m' and ($leader19=' ')">single unit</xsl:when>
						<xsl:when test="$leader7='m' and ($leader19='#')">single unit</xsl:when>
						<xsl:when test="$leader7='i'">integrating resource</xsl:when>
						<xsl:when test="$leader7='b' or $leader7='s'">serial</xsl:when>
					</xsl:choose>
				</issuance>
			</xsl:for-each>
			
			<!-- 1.96 20140422 -->
			<xsl:for-each select="marc:datafield[@tag=310]|marc:datafield[@tag=321]">
				<frequency>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">ab</xsl:with-param>
					</xsl:call-template>
				</frequency>
			</xsl:for-each>
			
			<!-- 1.67 1.72 updated fixed location issue 201308 1.86	-->
			
			<xsl:if test="$typeOf008='SE'">
				<xsl:for-each select="marc:controlfield[@tag=008]">
					<xsl:variable name="controlField008-18" select="substring($controlField008,19,1)"/>
					<xsl:variable name="frequency">
						<frequency>
							<xsl:choose>
								<xsl:when test="$controlField008-18='a'">Annual</xsl:when>
								<xsl:when test="$controlField008-18='b'">Bimonthly</xsl:when>
								<xsl:when test="$controlField008-18='c'">Semiweekly</xsl:when>
								<xsl:when test="$controlField008-18='d'">Daily</xsl:when>
								<xsl:when test="$controlField008-18='e'">Biweekly</xsl:when>
								<xsl:when test="$controlField008-18='f'">Semiannual</xsl:when>
								<xsl:when test="$controlField008-18='g'">Biennial</xsl:when>
								<xsl:when test="$controlField008-18='h'">Triennial</xsl:when>
								<xsl:when test="$controlField008-18='i'">Three times a week</xsl:when>
								<xsl:when test="$controlField008-18='j'">Three times a month</xsl:when>
								<xsl:when test="$controlField008-18='k'">Continuously updated</xsl:when>
								<xsl:when test="$controlField008-18='m'">Monthly</xsl:when>
								<xsl:when test="$controlField008-18='q'">Quarterly</xsl:when>
								<xsl:when test="$controlField008-18='s'">Semimonthly</xsl:when>
								<xsl:when test="$controlField008-18='t'">Three times a year</xsl:when>
								<xsl:when test="$controlField008-18='u'">Unknown</xsl:when>
								<xsl:when test="$controlField008-18='w'">Weekly</xsl:when>
								<!-- 1.106 20141218 -->
								<xsl:when test="$controlField008-18=' '">Completely irregular</xsl:when>
								<xsl:when test="$controlField008-18='#'">Completely irregular</xsl:when>
								<xsl:otherwise/>
							</xsl:choose>
						</frequency>
					</xsl:variable>
					<xsl:if test="$frequency!=''">
						<frequency authority="marcfrequency">
							<xsl:value-of select="$frequency"/>
						</frequency>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</originInfo>


		<!-- originInfo - 264 -->

		<xsl:for-each select="marc:datafield[@tag=264][@ind2=0]">
			<originInfo eventType="production">
				<!-- Template checks for altRepGroup - 880 $6 -->
				<xsl:call-template name="xxx880"/>
				<place>
					<placeTerm type="text">
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</placeTerm>
				</place>
				<publisher>
					<xsl:value-of select="marc:subfield[@code='b']"/>
				</publisher>
				<dateOther type="production">
					<xsl:value-of select="marc:subfield[@code='c']"/>
				</dateOther>
			</originInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=264][@ind2=1]">
			<originInfo eventType="publication">
				<!-- Template checks for altRepGroup - 880 $6 1.88 20130829 added chopPunc-->
				<xsl:call-template name="xxx880"/>
				<place>
						<placeTerm type="text">
							<xsl:value-of select="marc:subfield[@code='a']"/>
						</placeTerm>
				</place>
				<publisher>
					<xsl:value-of select="marc:subfield[@code='b']"/>
				</publisher>
				<dateIssued>
					<xsl:value-of select="marc:subfield[@code='c']"/>
				</dateIssued>
			</originInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=264][@ind2=2]">
			<originInfo eventType="distribution">
				<!-- Template checks for altRepGroup - 880 $6 -->
				<xsl:call-template name="xxx880"/>
				<place>
					<placeTerm type="text">
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</placeTerm>
				</place>
				<publisher>
					<xsl:value-of select="marc:subfield[@code='b']"/>
				</publisher>
				<dateOther type="distribution">
					<xsl:value-of select="marc:subfield[@code='c']"/>
				</dateOther>
			</originInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=264][@ind2=3]">
			<originInfo eventType="manufacture">
				<!-- Template checks for altRepGroup - 880 $6 -->
				<xsl:call-template name="xxx880"/>
				<place>
					<placeTerm type="text">
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</placeTerm>
				</place>
				<publisher>
					<xsl:value-of select="marc:subfield[@code='b']"/>
				</publisher>
				<dateOther type="manufacture">
					<xsl:value-of select="marc:subfield[@code='c']"/>
				</dateOther>
			</originInfo>
		</xsl:for-each>


		<xsl:for-each select="marc:datafield[@tag=880]">
			<xsl:variable name="related_datafield" select="substring-before(marc:subfield[@code='6'],'-')"/>
			<xsl:variable name="occurence_number" select="substring( substring-after(marc:subfield[@code='6'],'-') , 1 , 2 )"/>
			<xsl:variable name="hit" select="../marc:datafield[@tag=$related_datafield and contains(marc:subfield[@code='6'] , concat('880-' , $occurence_number))]/@tag"/>

			<xsl:choose>
				<xsl:when test="$hit='260'">
					<originInfo>
						<xsl:call-template name="scriptCode"/>
						<xsl:for-each select="../marc:datafield[@tag=260 and marc:subfield[@code='a' or code='b' or @code='c' or code='g']]">
							<xsl:call-template name="z2xx880"/>
						</xsl:for-each>
						<xsl:if test="marc:subfield[@code='a']">
							<place>
								<placeTerm type="text">
									<xsl:value-of select="marc:subfield[@code='a']"/>
								</placeTerm>
							</place>
						</xsl:if>
						<xsl:if test="marc:subfield[@code='b']">
							<publisher>
								<xsl:value-of select="marc:subfield[@code='b']"/>
							</publisher>
						</xsl:if>
						<xsl:if test="marc:subfield[@code='c']">
							<dateIssued>
								<xsl:value-of select="marc:subfield[@code='c']"/>
							</dateIssued>
						</xsl:if>
						<xsl:if test="marc:subfield[@code='g']">
							<dateCreated>
								<xsl:value-of select="marc:subfield[@code='g']"/>
							</dateCreated>
						</xsl:if>
						<xsl:for-each select="../marc:datafield[@tag=880]/marc:subfield[@code=6][contains(text(),'250')]">
							<edition>
								<xsl:value-of select="following-sibling::marc:subfield"/>
							</edition>
						</xsl:for-each>
					</originInfo>
				</xsl:when>
				<xsl:when test="$hit='300'">
					<physicalDescription>
						<xsl:for-each select="../marc:datafield[@tag=300]">
							<xsl:call-template name="z3xx880"/>
						</xsl:for-each>
						<extent>
							<xsl:for-each select="marc:subfield">
								<xsl:if test="@code='a' or @code='3' or @code='b' or @code='c'">
									<xsl:value-of select="."/>
									<xsl:text> </xsl:text>
								</xsl:if>
							</xsl:for-each>
						</extent>
						<!-- form 337 338 -->
						<form>
							<xsl:attribute name="authority">
								<xsl:value-of select="marc:subfield[@code='2']"/>
							</xsl:attribute>
							<xsl:call-template name="xxx880"/>
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">a</xsl:with-param>
							</xsl:call-template>
						</form>
					</physicalDescription>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>

		<!-- language 041 -->
		<xsl:variable name="controlField008-35-37" select="normalize-space(translate(substring($controlField008,36,3),'|#',''))"/>
		<xsl:if test="$controlField008-35-37">
			<language>
				<languageTerm authority="iso639-2b" type="code">
					<xsl:value-of select="substring($controlField008,36,3)"/>
				</languageTerm>
			</language>
		</xsl:if>
		<xsl:for-each select="marc:datafield[@tag=041]">
			<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='d' or @code='e' or @code='f' or @code='g' or @code='h']">
				<xsl:variable name="langCodes" select="."/>
				<xsl:choose>
					<xsl:when test="../marc:subfield[@code='2']='rfc3066'">
						<!-- not stacked but could be repeated -->
						<xsl:call-template name="rfcLanguages">
							<xsl:with-param name="nodeNum">
								<xsl:value-of select="1"/>
							</xsl:with-param>
							<xsl:with-param name="usedLanguages">
								<xsl:text/>
							</xsl:with-param>
							<xsl:with-param name="controlField008-35-37">
								<xsl:value-of select="$controlField008-35-37"/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- iso -->
						<xsl:variable name="allLanguages">
							<xsl:copy-of select="$langCodes"/>
						</xsl:variable>
						<xsl:variable name="currentLanguage">
							<xsl:value-of select="substring($allLanguages,1,3)"/>
						</xsl:variable>
						<xsl:call-template name="isoLanguage">
							<xsl:with-param name="currentLanguage">
								<xsl:value-of select="substring($allLanguages,1,3)"/>
							</xsl:with-param>
							<xsl:with-param name="remainingLanguages">
								<xsl:value-of select="substring($allLanguages,4,string-length($allLanguages)-3)"/>
							</xsl:with-param>
							<xsl:with-param name="usedLanguages">
								<xsl:if test="$controlField008-35-37">
									<xsl:value-of select="$controlField008-35-37"/>
								</xsl:if>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:for-each>

		<!-- physicalDescription -->

		<xsl:variable name="physicalDescription">
			<!--3.2 change tmee 007/11 -->
			<xsl:if test="$typeOf008='CF' and marc:controlfield[@tag=007][substring(.,12,1)='a']">
				<digitalOrigin>reformatted digital</digitalOrigin>
			</xsl:if>
			<xsl:if test="$typeOf008='CF' and marc:controlfield[@tag=007][substring(.,12,1)='b']">
				<digitalOrigin>digitized microfilm</digitalOrigin>
			</xsl:if>
			<xsl:if test="$typeOf008='CF' and marc:controlfield[@tag=007][substring(.,12,1)='d']">
				<digitalOrigin>digitized other analog</digitalOrigin>
			</xsl:if>
			<xsl:variable name="controlField008-23" select="substring($controlField008,24,1)"/>
			<xsl:variable name="controlField008-29" select="substring($controlField008,30,1)"/>
			<xsl:variable name="check008-23">
				<xsl:if test="$typeOf008='BK' or $typeOf008='MU' or $typeOf008='SE' or $typeOf008='MM'">
					<xsl:value-of select="true()"/>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="check008-29">
				<xsl:if test="$typeOf008='MP' or $typeOf008='VM'">
					<xsl:value-of select="true()"/>
				</xsl:if>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="($check008-23 and $controlField008-23='f') or ($check008-29 and $controlField008-29='f')">
					<form authority="marcform">braille</form>
				</xsl:when>
				<xsl:when test="($controlField008-23=' ' and ($leader6='c' or $leader6='d')) or (($typeOf008='BK' or $typeOf008='SE') and ($controlField008-23=' ' or $controlField008='r'))">
					<form authority="marcform">print</form>
				</xsl:when>
				<xsl:when test="$leader6 = 'm' or ($check008-23 and $controlField008-23='s') or ($check008-29 and $controlField008-29='s')">
					<form authority="marcform">electronic</form>
				</xsl:when>
				<!-- 1.33 -->
				<xsl:when test="$leader6 = 'o'">
					<form authority="marcform">kit</form>
				</xsl:when>
				<xsl:when test="($check008-23 and $controlField008-23='b') or ($check008-29 and $controlField008-29='b')">
					<form authority="marcform">microfiche</form>
				</xsl:when>
				<xsl:when test="($check008-23 and $controlField008-23='a') or ($check008-29 and $controlField008-29='a')">
					<form authority="marcform">microfilm</form>
				</xsl:when>
			</xsl:choose>

			<!-- 1/04 fix -->
			<xsl:if test="marc:datafield[@tag=130]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=130]/marc:subfield[@code='h']"/>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=240]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=240]/marc:subfield[@code='h']"/>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=242]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=242]/marc:subfield[@code='h']"/>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=245]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=245]/marc:subfield[@code='h']"/>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=246]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=246]/marc:subfield[@code='h']"/>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=730]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=730]/marc:subfield[@code='h']"/>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:for-each select="marc:datafield[@tag=256]/marc:subfield[@code='a']">
				<form>
					<xsl:value-of select="."/>
				</form>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=007][substring(text(),1,1)='c']">
				<xsl:choose>
					<xsl:when test="substring(text(),14,1)='a'">
						<reformattingQuality>access</reformattingQuality>
					</xsl:when>
					<xsl:when test="substring(text(),14,1)='p'">
						<reformattingQuality>preservation</reformattingQuality>
					</xsl:when>
					<xsl:when test="substring(text(),14,1)='r'">
						<reformattingQuality>replacement</reformattingQuality>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<!--3.2 change tmee 007/01 -->
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='b']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">chip cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='c']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">computer optical disc cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='j']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">magnetic disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='m']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">magneto-optical disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='o']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">optical disc</form>
			</xsl:if>

			<!-- 1.38 AQ 1.29 tmee 	1.66 added marccategory and marcsmd as part of 3.4 -->
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='r']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">remote</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='a']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">tape cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='f']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">tape cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='h']">
				<form authority="marccategory">electronic resource</form>
				<form authority="marcsmd">tape reel</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='a']">
				<form authority="marccategory">globe</form>
				<form authority="marcsmd">celestial globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='e']">
				<form authority="marccategory">globe</form>
				<form authority="marcsmd">earth moon globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='b']">
				<form authority="marccategory">globe</form>
				<form authority="marcsmd">planetary or lunar globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='c']">
				<form authority="marccategory">globe</form>
				<form authority="marcsmd">terrestrial globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='o'][substring(text(),2,1)='o']">
				<form authority="marccategory">kit</form>
				<form authority="marcsmd">kit</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='d']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">atlas</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='g']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">diagram</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='j']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">map</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='q']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">model</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='k']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">profile</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='r']">
				<form authority="marcsmd">remote-sensing image</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='s']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">section</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='y']">
				<form authority="marccategory">map</form>
				<form authority="marcsmd">view</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='a']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">aperture card</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='e']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">microfiche</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='f']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">microfiche cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='b']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">microfilm cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='c']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">microfilm cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='d']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">microfilm reel</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='g']">
				<form authority="marccategory">microform</form>
				<form authority="marcsmd">microopaque</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='m'][substring(text(),2,1)='c']">
				<form authority="marccategory">motion picture</form>
				<form authority="marcsmd">film cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='m'][substring(text(),2,1)='f']">
				<form authority="marccategory">motion picture</form>
				<form authority="marcsmd">film cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='m'][substring(text(),2,1)='r']">
				<form authority="marccategory">motion picture</form>
				<form authority="marcsmd">film reel</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='n']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">chart</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='c']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">collage</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='d']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">drawing</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='o']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">flash card</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='e']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">painting</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='f']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">photomechanical print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='g']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">photonegative</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='h']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">photoprint</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='i']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">picture</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='j']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='l']">
				<form authority="marccategory">nonprojected graphic</form>
				<form authority="marcsmd">technical drawing</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='q'][substring(text(),2,1)='q']">
				<form authority="marccategory">notated music</form>
				<form authority="marcsmd">notated music</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='d']">
				<form authority="marccategory">projected graphic</form>
				<form authority="marcsmd">filmslip</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='c']">
				<form authority="marccategory">projected graphic</form>
				<form authority="marcsmd">filmstrip cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='o']">
				<form authority="marccategory">projected graphic</form>
				<form authority="marcsmd">filmstrip roll</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='f']">
				<form authority="marccategory">projected graphic</form>
				<form authority="marcsmd">other filmstrip type</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='s']">
				<form authority="marccategory">projected graphic</form>
				<form authority="marcsmd">slide</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='t']">
				<form authority="marccategory">projected graphic</form>
				<form authority="marcsmd">transparency</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='r'][substring(text(),2,1)='r']">
				<form authority="marccategory">remote-sensing image</form>
				<form authority="marcsmd">remote-sensing image</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='e']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">cylinder</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='q']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">roll</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='g']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">sound cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='s']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">sound cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='d']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">sound disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='t']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">sound-tape reel</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='i']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">sound-track film</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='w']">
				<form authority="marccategory">sound recording</form>
				<form authority="marcsmd">wire recording</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='c']">
				<form authority="marccategory">tactile material</form>
				<form authority="marcsmd">braille</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='b']">
				<form authority="marccategory">tactile material</form>
				<form authority="marcsmd">combination</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='a']">
				<form authority="marccategory">tactile material</form>
				<form authority="marcsmd">moon</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='d']">
				<form authority="marccategory">tactile material</form>
				<form authority="marcsmd">tactile, with no writing system</form>
			</xsl:if>

			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='c']">
				<form authority="marccategory">text</form>
				<form authority="marcsmd">braille</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='b']">
				<form authority="marccategory">text</form>
				<form authority="marcsmd">large print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='a']">
				<form authority="marccategory">text</form>
				<form authority="marcsmd">regular print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='d']">
				<form authority="marccategory">text</form>
				<form authority="marcsmd">text in looseleaf binder</form>
			</xsl:if>

			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='c']">
				<form authority="marccategory">videorecording</form>
				<form authority="marcsmd">videocartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='f']">
				<form authority="marccategory">videorecording</form>
				<form authority="marcsmd">videocassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='d']">
				<form authority="marccategory">videorecording</form>
				<form authority="marcsmd">videodisc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='r']">
				<form authority="marccategory">videorecording</form>
				<form authority="marcsmd">videoreel</form>
			</xsl:if>

			<xsl:for-each select="marc:datafield[@tag=856]/marc:subfield[@code='q'][string-length(.)&gt;1]">
				<internetMediaType>
					<xsl:value-of select="."/>
				</internetMediaType>
			</xsl:for-each>

			<xsl:for-each select="marc:datafield[@tag=300]">
				<extent>
					<xsl:if test="marc:subfield[@code='f']">
						<xsl:attribute name="unit">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">f</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abce3g</xsl:with-param>
					</xsl:call-template>
				</extent>
			</xsl:for-each>


			<xsl:for-each select="marc:datafield[@tag=337]">
				<form type="media">
					<xsl:attribute name="authority">
						<xsl:value-of select="marc:subfield[@code=2]"/>
					</xsl:attribute>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:for-each>

			<xsl:for-each select="marc:datafield[@tag=338]">
				<form type="carrier">
					<xsl:attribute name="authority">
						<xsl:value-of select="marc:subfield[@code=2]"/>
					</xsl:attribute>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:for-each>


			<!-- 1.43 tmee 351 $3$a$b$c-->
			<xsl:for-each select="marc:datafield[@tag=351]">
				<note type="arrangement">
					<xsl:for-each select="marc:subfield[@code='3']">
						<xsl:value-of select="."/>
						<xsl:text>: </xsl:text>
					</xsl:for-each>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abc</xsl:with-param>
					</xsl:call-template>
				</note>
			</xsl:for-each>

		</xsl:variable>


		<xsl:if test="string-length(normalize-space($physicalDescription))">
			<physicalDescription>
				<xsl:for-each select="marc:datafield[@tag=300]">
					<!-- Template checks for altRepGroup - 880 $6 -->
					<xsl:call-template name="z3xx880"/>
				</xsl:for-each>
				<xsl:for-each select="marc:datafield[@tag=337]">
					<!-- Template checks for altRepGroup - 880 $6 -->
					<xsl:call-template name="xxx880"/>
				</xsl:for-each>
				<xsl:for-each select="marc:datafield[@tag=338]">
					<!-- Template checks for altRepGroup - 880 $6 -->
					<xsl:call-template name="xxx880"/>
				</xsl:for-each>

				<xsl:copy-of select="$physicalDescription"/>
			</physicalDescription>
		</xsl:if>


		<xsl:for-each select="marc:datafield[@tag=520]">
			<xsl:call-template name="createAbstractFrom520"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=505]">
			<xsl:call-template name="createTOCFrom505"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=521]">
			<xsl:call-template name="createTargetAudienceFrom521"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=506]">
			<xsl:call-template name="createAccessConditionFrom506"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=540]">
			<xsl:call-template name="createAccessConditionFrom540"/>
		</xsl:for-each>


		<xsl:if test="$typeOf008='BK' or $typeOf008='CF' or $typeOf008='MU' or $typeOf008='VM'">
			<xsl:variable name="controlField008-22" select="substring($controlField008,23,1)"/>
			<xsl:choose>
				<!-- 01/04 fix -->
				<xsl:when test="$controlField008-22='d'">
					<targetAudience authority="marctarget">adolescent</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='e'">
					<targetAudience authority="marctarget">adult</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='g'">
					<targetAudience authority="marctarget">general</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='b' or $controlField008-22='c' or $controlField008-22='j'">
					<targetAudience authority="marctarget">juvenile</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='a'">
					<targetAudience authority="marctarget">preschool</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='f'">
					<targetAudience authority="marctarget">specialized</targetAudience>
				</xsl:when>
			</xsl:choose>
		</xsl:if>

		<!-- 1.32 tmee Drop note mapping for 510 and map only to <relatedItem>
		<xsl:for-each select="marc:datafield[@tag=510]">
			<note type="citation/reference">
				<xsl:call-template name="uri"/>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
			</note>
		</xsl:for-each>
		-->

		<!-- 245c 362az 502-585 5XX-->

		<xsl:for-each select="marc:datafield[@tag=245]">
			<xsl:call-template name="createNoteFrom245c"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=362]">
			<xsl:call-template name="createNoteFrom362"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=500]">
			<xsl:call-template name="createNoteFrom500"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=502]">
			<xsl:call-template name="createNoteFrom502"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=504]">
			<xsl:call-template name="createNoteFrom504"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=508]">
			<xsl:call-template name="createNoteFrom508"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=511]">
			<xsl:call-template name="createNoteFrom511"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=515]">
			<xsl:call-template name="createNoteFrom515"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=518]">
			<xsl:call-template name="createNoteFrom518"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=524]">
			<xsl:call-template name="createNoteFrom524"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=530]">
			<xsl:call-template name="createNoteFrom530"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=533]">
			<xsl:call-template name="createNoteFrom533"/>
		</xsl:for-each>
		<!--
		<xsl:for-each select="marc:datafield[@tag=534]">
			<xsl:call-template name="createNoteFrom534"/>
		</xsl:for-each>
-->

		<xsl:for-each select="marc:datafield[@tag=535]">
			<xsl:call-template name="createNoteFrom535"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=536]">
			<xsl:call-template name="createNoteFrom536"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=538]">
			<xsl:call-template name="createNoteFrom538"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=541]">
			<xsl:call-template name="createNoteFrom541"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=545]">
			<xsl:call-template name="createNoteFrom545"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=546]">
			<xsl:call-template name="createNoteFrom546"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=561]">
			<xsl:call-template name="createNoteFrom561"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=562]">
			<xsl:call-template name="createNoteFrom562"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=581]">
			<xsl:call-template name="createNoteFrom581"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=583]">
			<xsl:call-template name="createNoteFrom583"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=585]">
			<xsl:call-template name="createNoteFrom585"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=501 or @tag=507 or @tag=513 or @tag=514 or @tag=516 or @tag=522 or @tag=525 or @tag=526 or @tag=544 or @tag=547 or @tag=550 or @tag=552 or @tag=555 or @tag=556 or @tag=565 or @tag=567 or @tag=580 or @tag=584 or @tag=586]">
			<xsl:call-template name="createNoteFrom5XX"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=034]">
			<xsl:call-template name="createSubGeoFrom034"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=043]">
			<xsl:call-template name="createSubGeoFrom043"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=045]">
			<xsl:call-template name="createSubTemFrom045"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=255]">
			<xsl:call-template name="createSubGeoFrom255"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=600]">
			<xsl:call-template name="createSubNameFrom600"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=610]">
			<xsl:call-template name="createSubNameFrom610"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=611]">
			<xsl:call-template name="createSubNameFrom611"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=630]">
			<xsl:call-template name="createSubTitleFrom630"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=648]">
			<xsl:call-template name="createSubChronFrom648"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=650]">
			<xsl:call-template name="createSubTopFrom650"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=651]">
			<xsl:call-template name="createSubGeoFrom651"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=653]">
			<xsl:call-template name="createSubFrom653"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=656]">
			<xsl:call-template name="createSubFrom656"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=662]">
			<xsl:call-template name="createSubGeoFrom662752"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=752]">
			<xsl:call-template name="createSubGeoFrom662752"/>
		</xsl:for-each>

		<!-- createClassificationFrom 0XX-->
		<xsl:for-each select="marc:datafield[@tag='050']">
			<xsl:call-template name="createClassificationFrom050"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='060']">
			<xsl:call-template name="createClassificationFrom060"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='080']">
			<xsl:call-template name="createClassificationFrom080"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='082']">
			<xsl:call-template name="createClassificationFrom082"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='084']">
			<xsl:call-template name="createClassificationFrom084"/>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='086']">
			<xsl:call-template name="createClassificationFrom086"/>
		</xsl:for-each>

		<!--	location	-->

		<xsl:for-each select="marc:datafield[@tag=852]">
			<xsl:call-template name="createLocationFrom852"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=856]">
			<xsl:call-template name="createLocationFrom856"/>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=490][@ind1=0]">
			<xsl:call-template name="createRelatedItemFrom490"/>
		</xsl:for-each>


		<xsl:for-each select="marc:datafield[@tag=440]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">av</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
			</relatedItem>
		</xsl:for-each>

		<!-- tmee 1.40 1.74 1.88 fixed 510c mapping 20130829-->

		<xsl:for-each select="marc:datafield[@tag=510]">
			<relatedItem type="isReferencedBy">
				<xsl:for-each select="marc:subfield[@code='a']">
					<titleInfo>
						<title>
							<xsl:value-of select="."/>
						</title>
					</titleInfo>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='b']">
					<originInfo>
						<dateOther type="coverage">
							<xsl:value-of select="."/>
						</dateOther>
					</originInfo>
				</xsl:for-each>
				
				<part>
					<detail type="part">
						<number>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">c</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
						</number>
					</detail>
					</part>
			</relatedItem>
		</xsl:for-each>


		<xsl:for-each select="marc:datafield[@tag=534]">
			<relatedItem type="original">
				<xsl:call-template name="relatedTitle"/>
				<xsl:call-template name="relatedName"/>
				<xsl:if test="marc:subfield[@code='b' or @code='c']">
					<originInfo>
						<xsl:for-each select="marc:subfield[@code='c']">
							<publisher>
								<xsl:value-of select="."/>
							</publisher>
						</xsl:for-each>
						<xsl:for-each select="marc:subfield[@code='b']">
							<edition>
								<xsl:value-of select="."/>
							</edition>
						</xsl:for-each>
					</originInfo>
				</xsl:if>
				<xsl:call-template name="relatedIdentifierISSN"/>
				<xsl:for-each select="marc:subfield[@code='z']">
					<identifier type="isbn">
						<xsl:value-of select="."/>
					</identifier>
				</xsl:for-each>
				<xsl:call-template name="relatedNote"/>
			</relatedItem>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=700][marc:subfield[@code='t']]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"/>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
				<name type="personal">
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">aq</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">g</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="termsOfAddress"/>
					<xsl:call-template name="nameDate"/>
					<xsl:call-template name="role"/>
				</name>
				<xsl:call-template name="relatedForm"/>
				<xsl:call-template name="relatedIdentifierISSN"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=710][marc:subfield[@code='t']]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"/>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">dg</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"/>
				</titleInfo>
				<name type="corporate">
					<xsl:for-each select="marc:subfield[@code='a']">
						<namePart>
							<xsl:value-of select="."/>
						</namePart>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='b']">
						<namePart>
							<xsl:value-of select="."/>
						</namePart>
					</xsl:for-each>
					<xsl:variable name="tempNamePart">
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">c</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">dgn</xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:if test="normalize-space($tempNamePart)">
						<namePart>
							<xsl:value-of select="$tempNamePart"/>
						</namePart>
					</xsl:if>
					<xsl:call-template name="role"/>
				</name>
				<xsl:call-template name="relatedForm"/>
				<xsl:call-template name="relatedIdentifierISSN"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=711][marc:subfield[@code='t']]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"/>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"/>
				</titleInfo>
				<name type="conference">
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">aqdc</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">gn</xsl:with-param>
						</xsl:call-template>
					</namePart>
				</name>
				<xsl:call-template name="relatedForm"/>
				<xsl:call-template name="relatedIdentifierISSN"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=730][@ind2=2]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"/>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">adfgklmorsv</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
				<xsl:call-template name="relatedForm"/>
				<xsl:call-template name="relatedIdentifierISSN"/>
			</relatedItem>
		</xsl:for-each>


		<xsl:for-each select="marc:datafield[@tag=740][@ind2=2]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"/>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:value-of select="marc:subfield[@code='a']"/>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=760]">
			<relatedItem type="series">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>

		<!--AQ1.23 tmee/dlf -->
		<xsl:for-each select="marc:datafield[@tag=762]">
			<relatedItem type="constituent">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>

		<!-- AQ1.5, AQ1.7 deleted tags 777 and 787 from the following select for relatedItem mapping -->
		<!-- 1.45 and 1.46 - AQ1.24 and 1.25 tmee-->
		<xsl:for-each select="marc:datafield[@tag=765]|marc:datafield[@tag=767]|marc:datafield[@tag=775]">
			<relatedItem type="otherVersion">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag=770]|marc:datafield[@tag=774]">
			<relatedItem type="constituent">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>


		<xsl:for-each select="marc:datafield[@tag=772]|marc:datafield[@tag=773]">
			<relatedItem type="host">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=776]">
			<relatedItem type="otherFormat">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=780]">
			<relatedItem type="preceding">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=785]">
			<relatedItem type="succeeding">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=786]">
			<relatedItem type="original">
				<xsl:call-template name="relatedItem76X-78X"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=800]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
				<name type="personal">
					<namePart>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">aq</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="beforeCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="termsOfAddress"/>
					<xsl:call-template name="nameDate"/>
					<xsl:call-template name="role"/>
				</name>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=810]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">dg</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"/>
				</titleInfo>
				<name type="corporate">
					<xsl:for-each select="marc:subfield[@code='a']">
						<namePart>
							<xsl:value-of select="."/>
						</namePart>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='b']">
						<namePart>
							<xsl:value-of select="."/>
						</namePart>
					</xsl:for-each>
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">c</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">dgn</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="role"/>
				</name>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=811]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"/>
				</titleInfo>
				<name type="conference">
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">aqdc</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">gn</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="role"/>
				</name>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='830']">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">adfgklmorsv</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='856'][@ind2='2']/marc:subfield[@code='q']">
			<relatedItem>
				<internetMediaType>
					<xsl:value-of select="."/>
				</internetMediaType>
			</relatedItem>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='880']">
			<xsl:apply-templates select="self::*" mode="trans880"/>
		</xsl:for-each>


		<!-- 856, 020, 024, 022, 028, 010, 035, 037 -->

		<xsl:for-each select="marc:datafield[@tag='020']">
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="isbn">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='020']">
			<xsl:if test="marc:subfield[@code='z']">
				<identifier type="isbn" invalid="yes">
					<xsl:value-of select="marc:subfield[@code='z']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='0']">
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="isrc">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='2']">
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="ismn">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='4']">
			<identifier type="sici">
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='8']">
			<identifier>
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</identifier>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='022'][marc:subfield[@code='a']]">
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="issn">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='022'][marc:subfield[@code='z']]">
			<xsl:if test="marc:subfield[@code='z']">
				<identifier type="issn" invalid="yes">
					<xsl:value-of select="marc:subfield[@code='z']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='022'][marc:subfield[@code='y']]">
			<xsl:if test="marc:subfield[@code='y']">
				<identifier type="issn" invalid="yes">
					<xsl:value-of select="marc:subfield[@code='y']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='022'][marc:subfield[@code='l']]">
			<xsl:if test="marc:subfield[@code='l']">
				<identifier type="issn-l">
					<xsl:value-of select="marc:subfield[@code='l']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='022'][marc:subfield[@code='m']]">
			<xsl:if test="marc:subfield[@code='m']">
				<identifier type="issn-l" invalid="yes">
					<xsl:value-of select="marc:subfield[@code='m']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='010'][marc:subfield[@code='a']]">
			<identifier type="lccn">
				<xsl:value-of select="normalize-space(marc:subfield[@code='a'])"/>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='010'][marc:subfield[@code='z']]">
			<identifier type="lccn" invalid="yes">
				<xsl:value-of select="normalize-space(marc:subfield[@code='z'])"/>
			</identifier>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='028']">
			<identifier>
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="@ind1='0'">issue number</xsl:when>
						<xsl:when test="@ind1='1'">matrix number</xsl:when>
						<xsl:when test="@ind1='2'">music plate</xsl:when>
						<xsl:when test="@ind1='3'">music publisher</xsl:when>
						<xsl:when test="@ind1='4'">videorecording identifier</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">
						<xsl:choose>
							<xsl:when test="@ind1='0'">ba</xsl:when>
							<xsl:otherwise>ab</xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
				</xsl:call-template>
			</identifier>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='035'][marc:subfield[@code='a'][contains(text(), '(OCoLC)')]]">
			<identifier type="oclc">
				<xsl:value-of select="normalize-space(substring-after(marc:subfield[@code='a'], '(OCoLC)'))"/>
			</identifier>
		</xsl:for-each>
		
		
		<!-- 3.5 1.95 20140421 -->
		<xsl:for-each select="marc:datafield[@tag='035'][marc:subfield[@code='a'][contains(text(), '(WlCaITV)')]]">
			<identifier type="WlCaITV">
				<xsl:value-of select="normalize-space(substring-after(marc:subfield[@code='a'], '(WlCaITV)'))"/>
			</identifier>
		</xsl:for-each>

		<xsl:for-each select="marc:datafield[@tag='037']">
			<identifier type="stock number">
				<xsl:if test="marc:subfield[@code='c']">
					<xsl:attribute name="displayLabel">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">c</xsl:with-param>
						</xsl:call-template>
					</xsl:attribute>
				</xsl:if>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</identifier>
		</xsl:for-each>


		<!-- 1.51 tmee 20100129-->
		<xsl:for-each select="marc:datafield[@tag='856'][marc:subfield[@code='u']]">
			<xsl:if test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl') or starts-with(marc:subfield[@code='u'],'http://hdl.loc.gov') ">
				<identifier>
					<xsl:attribute name="type">
						<xsl:if test="starts-with(marc:subfield[@code='u'],'urn:doi') or starts-with(marc:subfield[@code='u'],'doi')">doi</xsl:if>
						<xsl:if test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl') or starts-with(marc:subfield[@code='u'],'http://hdl.loc.gov')">hdl</xsl:if>
					</xsl:attribute>
					<xsl:value-of select="concat('hdl:',substring-after(marc:subfield[@code='u'],'http://hdl.loc.gov/'))"/>
				</identifier>
			</xsl:if>
			<xsl:if test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl')">
				<identifier type="hdl">
					<xsl:if test="marc:subfield[@code='y' or @code='3' or @code='z']">
						<xsl:attribute name="displayLabel">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">y3z</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="concat('hdl:',substring-after(marc:subfield[@code='u'],'http://hdl.loc.gov/'))"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=024][@ind1=1]">
			<identifier type="upc">
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</identifier>
		</xsl:for-each>


		<!-- 1.51 tmee 20100129 removed duplicate code 20131217
		<xsl:for-each select="marc:datafield[@tag='856'][marc:subfield[@code='u']]">
			<xsl:if
				test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl') or starts-with(marc:subfield[@code='u'],'http://hdl.loc.gov') ">
				<identifier>
					<xsl:attribute name="type">
						<xsl:if
							test="starts-with(marc:subfield[@code='u'],'urn:doi') or starts-with(marc:subfield[@code='u'],'doi')"
							>doi</xsl:if>
						<xsl:if
							test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl') or starts-with(marc:subfield[@code='u'],'http://hdl.loc.gov')"
							>hdl</xsl:if>
					</xsl:attribute>
					<xsl:value-of
						select="concat('hdl:',substring-after(marc:subfield[@code='u'],'http://hdl.loc.gov/'))"
					/>
				</identifier>
			</xsl:if>

			<xsl:if
				test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl')">
				<identifier type="hdl">
					<xsl:if test="marc:subfield[@code='y' or @code='3' or @code='z']">
						<xsl:attribute name="displayLabel">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">y3z</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of
						select="concat('hdl:',substring-after(marc:subfield[@code='u'],'http://hdl.loc.gov/'))"
					/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		-->


		<xsl:for-each select="marc:datafield[@tag=856][@ind2=2][marc:subfield[@code='u']]">
			<relatedItem>
				<location>
					<url>
						<xsl:if test="marc:subfield[@code='y' or @code='3']">
							<xsl:attribute name="displayLabel">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">y3</xsl:with-param>
								</xsl:call-template>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="marc:subfield[@code='z']">
							<xsl:attribute name="note">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">z</xsl:with-param>
								</xsl:call-template>
							</xsl:attribute>
						</xsl:if>
						<xsl:value-of select="marc:subfield[@code='u']"/>
					</url>
				</location>
			</relatedItem>
		</xsl:for-each>

		<recordInfo>
			<xsl:for-each select="marc:leader[substring($leader,19,1)='a']">
				<descriptionStandard>aacr</descriptionStandard>
			</xsl:for-each>

			<xsl:for-each select="marc:datafield[@tag=040]">
				<xsl:if test="marc:subfield[@code='e']">
					<descriptionStandard>
						<xsl:value-of select="marc:subfield[@code='e']"/>
					</descriptionStandard>
				</xsl:if>
				<recordContentSource authority="marcorg">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</recordContentSource>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=008]">
				<recordCreationDate encoding="marc">
					<xsl:value-of select="substring(.,1,6)"/>
				</recordCreationDate>
			</xsl:for-each>

			<xsl:for-each select="marc:controlfield[@tag=005]">
				<recordChangeDate encoding="iso8601">
					<xsl:value-of select="."/>
				</recordChangeDate>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=001]">
				<recordIdentifier>
					<xsl:if test="../marc:controlfield[@tag=003]">
						<xsl:attribute name="source">
							<xsl:value-of select="../marc:controlfield[@tag=003]"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="."/>
				</recordIdentifier>
			</xsl:for-each>

			<recordOrigin>Converted from MARCXML to MODS version 3.5 using MARC21slim2MODS3-5.xsl
				(Revision 1.106 2014/12/19)</recordOrigin>

			<xsl:for-each select="marc:datafield[@tag=040]/marc:subfield[@code='b']">
				<languageOfCataloging>
					<languageTerm authority="iso639-2b" type="code">
						<xsl:value-of select="."/>
					</languageTerm>
				</languageOfCataloging>
			</xsl:for-each>
		</recordInfo>
	</xsl:template>

	<xsl:template name="displayForm">
		<xsl:for-each select="marc:subfield[@code='c']">
			<displayForm>
				<xsl:value-of select="."/>
			</displayForm>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="affiliation">
		<xsl:for-each select="marc:subfield[@code='u']">
			<affiliation>
				<xsl:value-of select="."/>
			</affiliation>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="uri">
		<xsl:for-each select="marc:subfield[@code='u']|marc:subfield[@code='0']">
			<xsl:attribute name="xlink:href">
				<xsl:value-of select="."/>
			</xsl:attribute>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="role">
		<xsl:for-each select="marc:subfield[@code='e']">
			<role>
				<roleTerm type="text">
					<xsl:value-of select="."/>
				</roleTerm>
			</role>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='4']">
			<role>
				<roleTerm authority="marcrelator" type="code">
					<xsl:value-of select="."/>
				</roleTerm>
			</role>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="part">
		<xsl:variable name="partNumber">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">n</xsl:with-param>
				<xsl:with-param name="anyCodes">n</xsl:with-param>
				<xsl:with-param name="afterCodes">fgkdlmor</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="partName">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">p</xsl:with-param>
				<xsl:with-param name="anyCodes">p</xsl:with-param>
				<xsl:with-param name="afterCodes">fgkdlmor</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length(normalize-space($partNumber))">
			<partNumber>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="$partNumber"/>
				</xsl:call-template>
			</partNumber>
		</xsl:if>
		<xsl:if test="string-length(normalize-space($partName))">
			<partName>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="$partName"/>
				</xsl:call-template>
			</partName>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedPart">
		<xsl:if test="@tag=773">
			<xsl:for-each select="marc:subfield[@code='g']">
				<part>
					<text>
						<xsl:value-of select="."/>
					</text>
				</part>
			</xsl:for-each>
			<xsl:for-each select="marc:subfield[@code='q']">
				<part>
					<xsl:call-template name="parsePart"/>
				</part>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedPartNumName">
		<xsl:variable name="partNumber">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">g</xsl:with-param>
				<xsl:with-param name="anyCodes">g</xsl:with-param>
				<xsl:with-param name="afterCodes">pst</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="partName">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">p</xsl:with-param>
				<xsl:with-param name="anyCodes">p</xsl:with-param>
				<xsl:with-param name="afterCodes">fgkdlmor</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length(normalize-space($partNumber))">
			<partNumber>
				<xsl:value-of select="$partNumber"/>
			</partNumber>
		</xsl:if>
		<xsl:if test="string-length(normalize-space($partName))">
			<partName>
				<xsl:value-of select="$partName"/>
			</partName>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedName">
		<xsl:for-each select="marc:subfield[@code='a']">
			<name>
				<namePart>
					<xsl:value-of select="."/>
				</namePart>
			</name>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedForm">
		<xsl:for-each select="marc:subfield[@code='h']">
			<physicalDescription>
				<form>
					<xsl:value-of select="."/>
				</form>
			</physicalDescription>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedExtent">
		<xsl:for-each select="marc:subfield[@code='h']">
			<physicalDescription>
				<extent>
					<xsl:value-of select="."/>
				</extent>
			</physicalDescription>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedNote">
		<xsl:for-each select="marc:subfield[@code='n']">
			<note>
				<xsl:value-of select="."/>
			</note>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedSubject">
		<xsl:for-each select="marc:subfield[@code='j']">
			<subject>
				<temporal encoding="iso8601">
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString" select="."/>
					</xsl:call-template>
				</temporal>
			</subject>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedIdentifierISSN">
		<xsl:for-each select="marc:subfield[@code='x']">
			<identifier type="issn">
				<xsl:value-of select="."/>
			</identifier>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedIdentifierLocal">
		<xsl:for-each select="marc:subfield[@code='w']">
			<identifier type="local">
				<xsl:value-of select="."/>
			</identifier>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedIdentifier">
		<xsl:for-each select="marc:subfield[@code='o']">
			<identifier>
				<xsl:value-of select="."/>
			</identifier>
		</xsl:for-each>
	</xsl:template>

	<!--tmee 1.40 510 isReferencedBy -->
	<xsl:template name="relatedItem510">
		<xsl:call-template name="displayLabel"/>
		<xsl:call-template name="relatedTitle76X-78X"/>
		<xsl:call-template name="relatedName"/>
		<xsl:call-template name="relatedOriginInfo510"/>
		<xsl:call-template name="relatedLanguage"/>
		<xsl:call-template name="relatedExtent"/>
		<xsl:call-template name="relatedNote"/>
		<xsl:call-template name="relatedSubject"/>
		<xsl:call-template name="relatedIdentifier"/>
		<xsl:call-template name="relatedIdentifierISSN"/>
		<xsl:call-template name="relatedIdentifierLocal"/>
		<xsl:call-template name="relatedPart"/>
	</xsl:template>
	<xsl:template name="relatedItem76X-78X">
		<xsl:call-template name="displayLabel"/>
		<xsl:call-template name="relatedTitle76X-78X"/>
		<xsl:call-template name="relatedName"/>
		<xsl:call-template name="relatedOriginInfo"/>
		<xsl:call-template name="relatedLanguage"/>
		<xsl:call-template name="relatedExtent"/>
		<xsl:call-template name="relatedNote"/>
		<xsl:call-template name="relatedSubject"/>
		<xsl:call-template name="relatedIdentifier"/>
		<xsl:call-template name="relatedIdentifierISSN"/>
		<xsl:call-template name="relatedIdentifierLocal"/>
		<xsl:call-template name="relatedPart"/>
	</xsl:template>
	<xsl:template name="subjectGeographicZ">
		<geographic>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."/>
			</xsl:call-template>
		</geographic>
	</xsl:template>
	<xsl:template name="subjectTemporalY">
		<temporal>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."/>
			</xsl:call-template>
		</temporal>
	</xsl:template>
	<xsl:template name="subjectTopic">
		<topic>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."/>
			</xsl:call-template>
		</topic>
	</xsl:template>
	<!-- 3.2 change tmee 6xx $v genre -->
	<xsl:template name="subjectGenre">
		<genre>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."/>
			</xsl:call-template>
		</genre>
	</xsl:template>

	<xsl:template name="nameABCDN">
		<xsl:for-each select="marc:subfield[@code='a']">
			<namePart>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="."/>
				</xsl:call-template>
			</namePart>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='b']">
			<namePart>
				<xsl:value-of select="."/>
			</namePart>
		</xsl:for-each>
		<xsl:if test="marc:subfield[@code='c'] or marc:subfield[@code='d'] or marc:subfield[@code='n']">
			<namePart>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">cdn</xsl:with-param>
				</xsl:call-template>
			</namePart>
		</xsl:if>
	</xsl:template>
	<xsl:template name="nameABCDQ">
		<namePart>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">aq</xsl:with-param>
					</xsl:call-template>
				</xsl:with-param>
				<xsl:with-param name="punctuation">
					<xsl:text>:,;/ </xsl:text>
				</xsl:with-param>
			</xsl:call-template>
		</namePart>
		<xsl:call-template name="termsOfAddress"/>
		<xsl:call-template name="nameDate"/>
	</xsl:template>
	<xsl:template name="nameACDEQ">
		<namePart>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">acdeq</xsl:with-param>
			</xsl:call-template>
		</namePart>
	</xsl:template>
	
	<!--1.104 20141104-->
	<xsl:template name="nameACDENQ">
		<namePart>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">acdenq</xsl:with-param>
			</xsl:call-template>
		</namePart>
	</xsl:template>
	
	
	
	<xsl:template name="constituentOrRelatedType">
		<xsl:if test="@ind2=2">
			<xsl:attribute name="type">constituent</xsl:attribute>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedTitle">
		<xsl:for-each select="marc:subfield[@code='t']">
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</title>
			</titleInfo>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedTitle76X-78X">
		<xsl:for-each select="marc:subfield[@code='t']">
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:if test="marc:datafield[@tag!=773]and marc:subfield[@code='g']">
					<xsl:call-template name="relatedPartNumName"/>
				</xsl:if>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='p']">
			<titleInfo type="abbreviated">
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:if test="marc:datafield[@tag!=773]and marc:subfield[@code='g']">
					<xsl:call-template name="relatedPartNumName"/>
				</xsl:if>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='s']">
			<titleInfo type="uniform">
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:if test="marc:datafield[@tag!=773]and marc:subfield[@code='g']">
					<xsl:call-template name="relatedPartNumName"/>
				</xsl:if>
			</titleInfo>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedOriginInfo">
		<xsl:if test="marc:subfield[@code='b' or @code='d'] or marc:subfield[@code='f']">
			<originInfo>
				<xsl:if test="@tag=775">
					<xsl:for-each select="marc:subfield[@code='f']">
						<place>
							<placeTerm>
								<xsl:attribute name="type">code</xsl:attribute>
								<xsl:attribute name="authority">marcgac</xsl:attribute>
								<xsl:value-of select="."/>
							</placeTerm>
						</place>
					</xsl:for-each>
				</xsl:if>
				<xsl:for-each select="marc:subfield[@code='d']">
					<publisher>
						<xsl:value-of select="."/>
					</publisher>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='b']">
					<edition>
						<xsl:value-of select="."/>
					</edition>
				</xsl:for-each>
			</originInfo>
		</xsl:if>
	</xsl:template>

	<!-- tmee 1.40 -->

	<xsl:template name="relatedOriginInfo510">
		<xsl:for-each select="marc:subfield[@code='b']">
			<originInfo>
				<dateOther type="coverage">
					<xsl:value-of select="."/>
				</dateOther>
			</originInfo>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedLanguage">
		<xsl:for-each select="marc:subfield[@code='e']">
			<xsl:call-template name="getLanguage">
				<xsl:with-param name="langString">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="nameDate">
		<xsl:for-each select="marc:subfield[@code='d']">
			<namePart type="date">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="."/>
				</xsl:call-template>
			</namePart>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="subjectAuthority">
		<xsl:if test="@ind2!=4">
			<xsl:if test="@ind2!=' '">
				<xsl:if test="@ind2!=8">
					<xsl:if test="@ind2!=9">
						<xsl:attribute name="authority">
							<xsl:choose>
								<xsl:when test="@ind2=0">lcsh</xsl:when>
								<xsl:when test="@ind2=1">lcshac</xsl:when>
								<xsl:when test="@ind2=2">mesh</xsl:when>
								<!-- 1/04 fix -->
								<xsl:when test="@ind2=3">nal</xsl:when>
								<xsl:when test="@ind2=5">csh</xsl:when>
								<xsl:when test="@ind2=6">rvm</xsl:when>
								<xsl:when test="@ind2=7">
									<xsl:value-of select="marc:subfield[@code='2']"/>
								</xsl:when>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
				</xsl:if>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- 1.75 
		fix -->
	<xsl:template name="subject653Type">
		<xsl:if test="@ind2!=' '">
			<xsl:if test="@ind2!='0'">
				<xsl:if test="@ind2!='4'">
					<xsl:if test="@ind2!='5'">
						<xsl:if test="@ind2!='6'">
							<xsl:if test="@ind2!='7'">
								<xsl:if test="@ind2!='8'">
									<xsl:if test="@ind2!='9'">
										<xsl:attribute name="type">
											<xsl:choose>
												<xsl:when test="@ind2=1">personal</xsl:when>
												<xsl:when test="@ind2=2">corporate</xsl:when>
												<xsl:when test="@ind2=3">conference</xsl:when>
											</xsl:choose>
										</xsl:attribute>
									</xsl:if>
								</xsl:if>
							</xsl:if>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:if>
		</xsl:if>


	</xsl:template>
	<xsl:template name="subjectAnyOrder">
		<xsl:for-each select="marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']">
			<xsl:choose>
				<xsl:when test="@code='v'">
					<xsl:call-template name="subjectGenre"/>
				</xsl:when>
				<xsl:when test="@code='x'">
					<xsl:call-template name="subjectTopic"/>
				</xsl:when>
				<xsl:when test="@code='y'">
					<xsl:call-template name="subjectTemporalY"/>
				</xsl:when>
				<xsl:when test="@code='z'">
					<xsl:call-template name="subjectGeographicZ"/>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="specialSubfieldSelect">
		<xsl:param name="anyCodes"/>
		<xsl:param name="axis"/>
		<xsl:param name="beforeCodes"/>
		<xsl:param name="afterCodes"/>
		<xsl:variable name="str">
			<xsl:for-each select="marc:subfield">
				<xsl:if test="contains($anyCodes, @code) or (contains($beforeCodes,@code) and following-sibling::marc:subfield[@code=$axis])      or (contains($afterCodes,@code) and preceding-sibling::marc:subfield[@code=$axis])">
					<xsl:value-of select="text()"/>
					<xsl:text> </xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
	</xsl:template>


	<xsl:template match="marc:datafield[@tag=656]">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:if test="marc:subfield[@code=2]">
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code=2]"/>
				</xsl:attribute>
			</xsl:if>
			<occupation>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</xsl:with-param>
				</xsl:call-template>
			</occupation>
		</subject>
	</xsl:template>
	<xsl:template name="termsOfAddress">
		<xsl:if test="marc:subfield[@code='b' or @code='c']">
			<namePart type="termsOfAddress">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">bc</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</namePart>
		</xsl:if>
	</xsl:template>
	<xsl:template name="displayLabel">
		<xsl:if test="marc:subfield[@code='i']">
			<xsl:attribute name="displayLabel">
				<xsl:value-of select="marc:subfield[@code='i']"/>
			</xsl:attribute>
		</xsl:if>
		<xsl:if test="marc:subfield[@code='3']">
			<xsl:attribute name="displayLabel">
				<xsl:value-of select="marc:subfield[@code='3']"/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<!-- isInvalid
	<xsl:template name="isInvalid">
		<xsl:param name="type"/>
		<xsl:if
			test="marc:subfield[@code='z'] or marc:subfield[@code='y'] or marc:subfield[@code='m']">
			<identifier>
				<xsl:attribute name="type">
					<xsl:value-of select="$type"/>
				</xsl:attribute>
				<xsl:attribute name="invalid">
					<xsl:text>yes</xsl:text>
				</xsl:attribute>
				<xsl:if test="marc:subfield[@code='z']">
					<xsl:value-of select="marc:subfield[@code='z']"/>
				</xsl:if>
				<xsl:if test="marc:subfield[@code='y']">
					<xsl:value-of select="marc:subfield[@code='y']"/>
				</xsl:if>
				<xsl:if test="marc:subfield[@code='m']">
					<xsl:value-of select="marc:subfield[@code='m']"/>
				</xsl:if>
			</identifier>
		</xsl:if>
	</xsl:template>
	-->
	<xsl:template name="subtitle">
		<xsl:if test="marc:subfield[@code='b']">
			<subTitle>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="marc:subfield[@code='b']"/>
						<!--<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">b</xsl:with-param>									
						</xsl:call-template>-->
					</xsl:with-param>
				</xsl:call-template>
			</subTitle>
		</xsl:if>
	</xsl:template>
	<xsl:template name="script">
		<xsl:param name="scriptCode"/>
		<xsl:attribute name="script">
			<xsl:choose>
				<!-- ISO 15924	and CJK is a local code	20101123-->
				<xsl:when test="$scriptCode='(3'">Arab</xsl:when>
				<xsl:when test="$scriptCode='(4'">Arab</xsl:when>
				<xsl:when test="$scriptCode='(B'">Latn</xsl:when>
				<xsl:when test="$scriptCode='!E'">Latn</xsl:when>
				<xsl:when test="$scriptCode='$1'">CJK</xsl:when>
				<xsl:when test="$scriptCode='(N'">Cyrl</xsl:when>
				<xsl:when test="$scriptCode='(Q'">Cyrl</xsl:when>
				<xsl:when test="$scriptCode='(2'">Hebr</xsl:when>
				<xsl:when test="$scriptCode='(S'">Grek</xsl:when>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>
	<xsl:template name="parsePart">
		<!-- assumes 773$q= 1:2:3<4
		     with up to 3 levels and one optional start page
		-->
		<xsl:variable name="level1">
			<xsl:choose>
				<xsl:when test="contains(text(),':')">
					<!-- 1:2 -->
					<xsl:value-of select="substring-before(text(),':')"/>
				</xsl:when>
				<xsl:when test="not(contains(text(),':'))">
					<!-- 1 or 1<3 -->
					<xsl:if test="contains(text(),'&lt;')">
						<!-- 1<3 -->
						<xsl:value-of select="substring-before(text(),'&lt;')"/>
					</xsl:if>
					<xsl:if test="not(contains(text(),'&lt;'))">
						<!-- 1 -->
						<xsl:value-of select="text()"/>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="sici2">
			<xsl:choose>
				<xsl:when test="starts-with(substring-after(text(),$level1),':')">
					<xsl:value-of select="substring(substring-after(text(),$level1),2)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-after(text(),$level1)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="level2">
			<xsl:choose>
				<xsl:when test="contains($sici2,':')">
					<!--  2:3<4  -->
					<xsl:value-of select="substring-before($sici2,':')"/>
				</xsl:when>
				<xsl:when test="contains($sici2,'&lt;')">
					<!-- 1: 2<4 -->
					<xsl:value-of select="substring-before($sici2,'&lt;')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$sici2"/>
					<!-- 1:2 -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="sici3">
			<xsl:choose>
				<xsl:when test="starts-with(substring-after($sici2,$level2),':')">
					<xsl:value-of select="substring(substring-after($sici2,$level2),2)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-after($sici2,$level2)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="level3">
			<xsl:choose>
				<xsl:when test="contains($sici3,'&lt;')">
					<!-- 2<4 -->
					<xsl:value-of select="substring-before($sici3,'&lt;')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$sici3"/>
					<!-- 3 -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="page">
			<xsl:if test="contains(text(),'&lt;')">
				<xsl:value-of select="substring-after(text(),'&lt;')"/>
			</xsl:if>
		</xsl:variable>
		<xsl:if test="$level1">
			<detail level="1">
				<number>
					<xsl:value-of select="$level1"/>
				</number>
			</detail>
		</xsl:if>
		<xsl:if test="$level2">
			<detail level="2">
				<number>
					<xsl:value-of select="$level2"/>
				</number>
			</detail>
		</xsl:if>
		<xsl:if test="$level3">
			<detail level="3">
				<number>
					<xsl:value-of select="$level3"/>
				</number>
			</detail>
		</xsl:if>
		<xsl:if test="$page">
			<extent unit="page">
				<start>
					<xsl:value-of select="$page"/>
				</start>
			</extent>
		</xsl:if>
	</xsl:template>
	<xsl:template name="getLanguage">
		<xsl:param name="langString"/>
		<xsl:param name="controlField008-35-37"/>
		<xsl:variable name="length" select="string-length($langString)"/>
		<xsl:choose>
			<xsl:when test="$length=0"/>
			<xsl:when test="$controlField008-35-37=substring($langString,1,3)">
				<xsl:call-template name="getLanguage">
					<xsl:with-param name="langString" select="substring($langString,4,$length)"/>
					<xsl:with-param name="controlField008-35-37" select="$controlField008-35-37"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<language>
					<languageTerm authority="iso639-2b" type="code">
						<xsl:value-of select="substring($langString,1,3)"/>
					</languageTerm>
				</language>
				<xsl:call-template name="getLanguage">
					<xsl:with-param name="langString" select="substring($langString,4,$length)"/>
					<xsl:with-param name="controlField008-35-37" select="$controlField008-35-37"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="isoLanguage">
		<xsl:param name="currentLanguage"/>
		<xsl:param name="usedLanguages"/>
		<xsl:param name="remainingLanguages"/>
		<xsl:choose>
			<xsl:when test="string-length($currentLanguage)=0"/>
			<xsl:when test="not(contains($usedLanguages, $currentLanguage))">
				<language>
					<xsl:if test="@code!='a'">
						<xsl:attribute name="objectPart">
							<xsl:choose>
								<xsl:when test="@code='b'">summary or subtitle</xsl:when>
								<xsl:when test="@code='d'">sung or spoken text</xsl:when>
								<xsl:when test="@code='e'">libretto</xsl:when>
								<xsl:when test="@code='f'">table of contents</xsl:when>
								<xsl:when test="@code='g'">accompanying material</xsl:when>
								<xsl:when test="@code='h'">translation</xsl:when>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
					<languageTerm authority="iso639-2b" type="code">
						<xsl:value-of select="$currentLanguage"/>
					</languageTerm>
				</language>
				<xsl:call-template name="isoLanguage">
					<xsl:with-param name="currentLanguage">
						<xsl:value-of select="substring($remainingLanguages,1,3)"/>
					</xsl:with-param>
					<xsl:with-param name="usedLanguages">
						<xsl:value-of select="concat($usedLanguages,$currentLanguage)"/>
					</xsl:with-param>
					<xsl:with-param name="remainingLanguages">
						<xsl:value-of select="substring($remainingLanguages,4,string-length($remainingLanguages))"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="isoLanguage">
					<xsl:with-param name="currentLanguage">
						<xsl:value-of select="substring($remainingLanguages,1,3)"/>
					</xsl:with-param>
					<xsl:with-param name="usedLanguages">
						<xsl:value-of select="concat($usedLanguages,$currentLanguage)"/>
					</xsl:with-param>
					<xsl:with-param name="remainingLanguages">
						<xsl:value-of select="substring($remainingLanguages,4,string-length($remainingLanguages))"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="chopBrackets">
		<xsl:param name="chopString"/>
		<xsl:variable name="string">
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="$chopString"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="substring($string, 1,1)='['">
			<xsl:value-of select="substring($string,2, string-length($string)-2)"/>
		</xsl:if>
		<xsl:if test="substring($string, 1,1)!='['">
			<xsl:value-of select="$string"/>
		</xsl:if>
	</xsl:template>
	<xsl:template name="rfcLanguages">
		<xsl:param name="nodeNum"/>
		<xsl:param name="usedLanguages"/>
		<xsl:param name="controlField008-35-37"/>
		<xsl:variable name="currentLanguage" select="."/>
		<xsl:choose>
			<xsl:when test="not($currentLanguage)"/>
			<xsl:when test="$currentLanguage!=$controlField008-35-37 and $currentLanguage!='rfc3066'">
				<xsl:if test="not(contains($usedLanguages,$currentLanguage))">
					<language>
						<xsl:if test="@code!='a'">
							<xsl:attribute name="objectPart">
								<xsl:choose>
									<xsl:when test="@code='b'">summary or subtitle</xsl:when>
									<xsl:when test="@code='d'">sung or spoken text</xsl:when>
									<xsl:when test="@code='e'">libretto</xsl:when>
									<xsl:when test="@code='f'">table of contents</xsl:when>
									<xsl:when test="@code='g'">accompanying material</xsl:when>
									<xsl:when test="@code='h'">translation</xsl:when>
								</xsl:choose>
							</xsl:attribute>
						</xsl:if>
						<languageTerm authority="rfc3066" type="code">
							<xsl:value-of select="$currentLanguage"/>
						</languageTerm>
					</language>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise> </xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- tmee added 20100106 for 045$b BC and CE date range info -->
	<xsl:template name="dates045b">
		<xsl:param name="str"/>
		<xsl:variable name="first-char" select="substring($str,1,1)"/>
		<xsl:choose>
			<xsl:when test="$first-char ='c'">
				<xsl:value-of select="concat ('-', substring($str, 2))"/>
			</xsl:when>
			<xsl:when test="$first-char ='d'">
				<xsl:value-of select="substring($str, 2)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="scriptCode">
		<xsl:variable name="sf06" select="normalize-space(child::marc:subfield[@code='6'])"/>
		<xsl:variable name="sf06a" select="substring($sf06, 1, 3)"/>
		<xsl:variable name="sf06b" select="substring($sf06, 5, 2)"/>
		<xsl:variable name="sf06c" select="substring($sf06, 7)"/>
		<xsl:variable name="scriptCode" select="substring($sf06, 8, 2)"/>
		<xsl:if test="//marc:datafield/marc:subfield[@code='6']">
			<xsl:attribute name="script">
				<xsl:choose>
					<xsl:when test="$scriptCode=''">Latn</xsl:when>
					<xsl:when test="$scriptCode='(3'">Arab</xsl:when>
					<xsl:when test="$scriptCode='(4'">Arab</xsl:when>
					<xsl:when test="$scriptCode='(B'">Latn</xsl:when>
					<xsl:when test="$scriptCode='!E'">Latn</xsl:when>
					<xsl:when test="$scriptCode='$1'">CJK</xsl:when>
					<xsl:when test="$scriptCode='(N'">Cyrl</xsl:when>
					<xsl:when test="$scriptCode='(Q'">Cyrl</xsl:when>
					<xsl:when test="$scriptCode='(2'">Hebr</xsl:when>
					<xsl:when test="$scriptCode='(S'">Grek</xsl:when>
				</xsl:choose>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<!-- tmee 20100927 for 880s & corresponding fields  20101123 scriptCode -->

	<xsl:template name="xxx880">
		<xsl:if test="child::marc:subfield[@code='6']">
			<xsl:variable name="sf06" select="normalize-space(child::marc:subfield[@code='6'])"/>
			<xsl:variable name="sf06a" select="substring($sf06, 1, 3)"/>
			<xsl:variable name="sf06b" select="substring($sf06, 5, 2)"/>
			<xsl:variable name="sf06c" select="substring($sf06, 7)"/>
			<xsl:variable name="scriptCode" select="substring($sf06, 8, 2)"/>
			<xsl:if test="//marc:datafield/marc:subfield[@code='6']">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$sf06b"/>
				</xsl:attribute>
				<xsl:attribute name="script">
					<xsl:choose>
						<xsl:when test="$scriptCode=''">Latn</xsl:when>
						<xsl:when test="$scriptCode='(3'">Arab</xsl:when>
						<xsl:when test="$scriptCode='(4'">Arab</xsl:when>
						<xsl:when test="$scriptCode='(B'">Latn</xsl:when>
						<xsl:when test="$scriptCode='!E'">Latn</xsl:when>
						<xsl:when test="$scriptCode='$1'">CJK</xsl:when>
						<xsl:when test="$scriptCode='(N'">Cyrl</xsl:when>
						<xsl:when test="$scriptCode='(Q'">Cyrl</xsl:when>
						<xsl:when test="$scriptCode='(2'">Hebr</xsl:when>
						<xsl:when test="$scriptCode='(S'">Grek</xsl:when>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template name="yyy880">
		<xsl:if test="preceding-sibling::marc:subfield[@code='6']">
			<xsl:variable name="sf06" select="normalize-space(preceding-sibling::marc:subfield[@code='6'])"/>
			<xsl:variable name="sf06a" select="substring($sf06, 1, 3)"/>
			<xsl:variable name="sf06b" select="substring($sf06, 5, 2)"/>
			<xsl:variable name="sf06c" select="substring($sf06, 7)"/>
			<xsl:if test="//marc:datafield/marc:subfield[@code='6']">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$sf06b"/>
				</xsl:attribute>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template name="z2xx880">
		<!-- Evaluating the 260 field -->
		<xsl:variable name="x260">
			<xsl:choose>
				<xsl:when test="@tag='260' and marc:subfield[@code='6']">
					<xsl:variable name="sf06260" select="normalize-space(child::marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06260a" select="substring($sf06260, 1, 3)"/>
					<xsl:variable name="sf06260b" select="substring($sf06260, 5, 2)"/>
					<xsl:variable name="sf06260c" select="substring($sf06260, 7)"/>
					<xsl:value-of select="$sf06260b"/>
				</xsl:when>
				<xsl:when test="@tag='250' and ../marc:datafield[@tag='260']/marc:subfield[@code='6']">
					<xsl:variable name="sf06260" select="normalize-space(../marc:datafield[@tag='260']/marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06260a" select="substring($sf06260, 1, 3)"/>
					<xsl:variable name="sf06260b" select="substring($sf06260, 5, 2)"/>
					<xsl:variable name="sf06260c" select="substring($sf06260, 7)"/>
					<xsl:value-of select="$sf06260b"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>            

		<xsl:variable name="x250">
			<xsl:choose>
				<xsl:when test="@tag='250' and marc:subfield[@code='6']">
					<xsl:variable name="sf06250" select="normalize-space(../marc:datafield[@tag='250']/marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06250a" select="substring($sf06250, 1, 3)"/>
					<xsl:variable name="sf06250b" select="substring($sf06250, 5, 2)"/>
					<xsl:variable name="sf06250c" select="substring($sf06250, 7)"/>
					<xsl:value-of select="$sf06250b"/>
				</xsl:when>
				<xsl:when test="@tag='260' and ../marc:datafield[@tag='250']/marc:subfield[@code='6']">
					<xsl:variable name="sf06250" select="normalize-space(../marc:datafield[@tag='250']/marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06250a" select="substring($sf06250, 1, 3)"/>
					<xsl:variable name="sf06250b" select="substring($sf06250, 5, 2)"/>
					<xsl:variable name="sf06250c" select="substring($sf06250, 7)"/>
					<xsl:value-of select="$sf06250b"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$x250!='' and $x260!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="concat($x250, $x260)"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="$x250!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$x250"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="$x260!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$x260"/>
				</xsl:attribute>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="//marc:datafield/marc:subfield[@code='6']"> </xsl:if>
	</xsl:template>

	<xsl:template name="z3xx880">
		<!-- Evaluating the 300 field -->
		<xsl:variable name="x300">
			<xsl:choose>
				<xsl:when test="@tag='300' and marc:subfield[@code='6']">
					<xsl:variable name="sf06300" select="normalize-space(child::marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06300a" select="substring($sf06300, 1, 3)"/>
					<xsl:variable name="sf06300b" select="substring($sf06300, 5, 2)"/>
					<xsl:variable name="sf06300c" select="substring($sf06300, 7)"/>
					<xsl:value-of select="$sf06300b"/>
				</xsl:when>
				<xsl:when test="@tag='351' and ../marc:datafield[@tag='300']/marc:subfield[@code='6']">
					<xsl:variable name="sf06300" select="normalize-space(../marc:datafield[@tag='300']/marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06300a" select="substring($sf06300, 1, 3)"/>
					<xsl:variable name="sf06300b" select="substring($sf06300, 5, 2)"/>
					<xsl:variable name="sf06300c" select="substring($sf06300, 7)"/>
					<xsl:value-of select="$sf06300b"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="x351">
			<xsl:choose>
				<xsl:when test="@tag='351' and marc:subfield[@code='6']">
					<xsl:variable name="sf06351" select="normalize-space(../marc:datafield[@tag='351']/marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06351a" select="substring($sf06351, 1, 3)"/>
					<xsl:variable name="sf06351b" select="substring($sf06351, 5, 2)"/>
					<xsl:variable name="sf06351c" select="substring($sf06351, 7)"/>
					<xsl:value-of select="$sf06351b"/>
				</xsl:when>
				<xsl:when test="@tag='300' and ../marc:datafield[@tag='351']/marc:subfield[@code='6']">
					<xsl:variable name="sf06351" select="normalize-space(../marc:datafield[@tag='351']/marc:subfield[@code='6'])"/>
					<xsl:variable name="sf06351a" select="substring($sf06351, 1, 3)"/>
					<xsl:variable name="sf06351b" select="substring($sf06351, 5, 2)"/>
					<xsl:variable name="sf06351c" select="substring($sf06351, 7)"/>
					<xsl:value-of select="$sf06351b"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="x337">
			<xsl:if test="@tag='337' and marc:subfield[@code='6']">
				<xsl:variable name="sf06337" select="normalize-space(child::marc:subfield[@code='6'])"/>
				<xsl:variable name="sf06337a" select="substring($sf06337, 1, 3)"/>
				<xsl:variable name="sf06337b" select="substring($sf06337, 5, 2)"/>
				<xsl:variable name="sf06337c" select="substring($sf06337, 7)"/>
				<xsl:value-of select="$sf06337b"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="x338">
			<xsl:if test="@tag='338' and marc:subfield[@code='6']">
				<xsl:variable name="sf06338" select="normalize-space(child::marc:subfield[@code='6'])"/>
				<xsl:variable name="sf06338a" select="substring($sf06338, 1, 3)"/>
				<xsl:variable name="sf06338b" select="substring($sf06338, 5, 2)"/>
				<xsl:variable name="sf06338c" select="substring($sf06338, 7)"/>
				<xsl:value-of select="$sf06338b"/>
			</xsl:if>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$x351!='' and $x300!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="concat($x351, $x300, $x337, $x338)"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="$x351!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$x351"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="$x300!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$x300"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="$x337!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$x351"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="$x338!=''">
				<xsl:attribute name="altRepGroup">
					<xsl:value-of select="$x300"/>
				</xsl:attribute>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="//marc:datafield/marc:subfield[@code='6']"> </xsl:if>
	</xsl:template>



	<xsl:template name="true880">
		<xsl:variable name="sf06" select="normalize-space(marc:subfield[@code='6'])"/>
		<xsl:variable name="sf06a" select="substring($sf06, 1, 3)"/>
		<xsl:variable name="sf06b" select="substring($sf06, 5, 2)"/>
		<xsl:variable name="sf06c" select="substring($sf06, 7)"/>
		<xsl:if test="//marc:datafield/marc:subfield[@code='6']">
			<xsl:attribute name="altRepGroup">
				<xsl:value-of select="$sf06b"/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<xsl:template match="marc:datafield" mode="trans880">
		<xsl:variable name="dataField880" select="//marc:datafield"/>
		<xsl:variable name="sf06" select="normalize-space(marc:subfield[@code='6'])"/>
		<xsl:variable name="sf06a" select="substring($sf06, 1, 3)"/>
		<xsl:variable name="sf06b" select="substring($sf06, 4)"/>
		<xsl:choose>

			<!--tranforms 880 equiv-->

			<xsl:when test="$sf06a='047'">
				<xsl:call-template name="createGenreFrom047"/>
			</xsl:when>
			<xsl:when test="$sf06a='336'">
				<xsl:call-template name="createGenreFrom336"/>
			</xsl:when>
			<xsl:when test="$sf06a='655'">
				<xsl:call-template name="createGenreFrom655"/>
			</xsl:when>

			<xsl:when test="$sf06a='050'">
				<xsl:call-template name="createClassificationFrom050"/>
			</xsl:when>
			<xsl:when test="$sf06a='060'">
				<xsl:call-template name="createClassificationFrom060"/>
			</xsl:when>
			<xsl:when test="$sf06a='080'">
				<xsl:call-template name="createClassificationFrom080"/>
			</xsl:when>
			<xsl:when test="$sf06a='082'">
				<xsl:call-template name="createClassificationFrom082"/>
			</xsl:when>
			<xsl:when test="$sf06a='084'">
				<xsl:call-template name="createClassificationFrom080"/>
			</xsl:when>
			<xsl:when test="$sf06a='086'">
				<xsl:call-template name="createClassificationFrom082"/>
			</xsl:when>
			<xsl:when test="$sf06a='100'">
				<xsl:call-template name="createNameFrom100"/>
			</xsl:when>
			<xsl:when test="$sf06a='110'">
				<xsl:call-template name="createNameFrom110"/>
			</xsl:when>
			<xsl:when test="$sf06a='111'">
				<xsl:call-template name="createNameFrom110"/>
			</xsl:when>
			<xsl:when test="$sf06a='700'">
				<xsl:call-template name="createNameFrom700"/>
			</xsl:when>
			<xsl:when test="$sf06a='710'">
				<xsl:call-template name="createNameFrom710"/>
			</xsl:when>
			<xsl:when test="$sf06a='711'">
				<xsl:call-template name="createNameFrom710"/>
			</xsl:when>
			<xsl:when test="$sf06a='210'">
				<xsl:call-template name="createTitleInfoFrom210"/>
			</xsl:when>
			<xsl:when test="$sf06a='245'">
				<xsl:call-template name="createTitleInfoFrom245"/>
				<xsl:call-template name="createNoteFrom245c"/>
			</xsl:when>
			<xsl:when test="$sf06a='246'">
				<xsl:call-template name="createTitleInfoFrom246"/>
			</xsl:when>
			<xsl:when test="$sf06a='240'">
				<xsl:call-template name="createTitleInfoFrom240"/>
			</xsl:when>
			<xsl:when test="$sf06a='740'">
				<xsl:call-template name="createTitleInfoFrom740"/>
			</xsl:when>

			<xsl:when test="$sf06a='130'">
				<xsl:call-template name="createTitleInfoFrom130"/>
			</xsl:when>
			<xsl:when test="$sf06a='730'">
				<xsl:call-template name="createTitleInfoFrom730"/>
			</xsl:when>

			<xsl:when test="$sf06a='505'">
				<xsl:call-template name="createTOCFrom505"/>
			</xsl:when>
			<xsl:when test="$sf06a='520'">
				<xsl:call-template name="createAbstractFrom520"/>
			</xsl:when>
			<xsl:when test="$sf06a='521'">
				<xsl:call-template name="createTargetAudienceFrom521"/>
			</xsl:when>
			<xsl:when test="$sf06a='506'">
				<xsl:call-template name="createAccessConditionFrom506"/>
			</xsl:when>
			<xsl:when test="$sf06a='540'">
				<xsl:call-template name="createAccessConditionFrom540"/>
			</xsl:when>

			<!-- note 245 362 etc	-->

			<xsl:when test="$sf06a='245'">
				<xsl:call-template name="createNoteFrom245c"/>
			</xsl:when>
			<xsl:when test="$sf06a='362'">
				<xsl:call-template name="createNoteFrom362"/>
			</xsl:when>
			<xsl:when test="$sf06a='502'">
				<xsl:call-template name="createNoteFrom502"/>
			</xsl:when>
			<xsl:when test="$sf06a='504'">
				<xsl:call-template name="createNoteFrom504"/>
			</xsl:when>
			<xsl:when test="$sf06a='508'">
				<xsl:call-template name="createNoteFrom508"/>
			</xsl:when>
			<xsl:when test="$sf06a='511'">
				<xsl:call-template name="createNoteFrom511"/>
			</xsl:when>
			<xsl:when test="$sf06a='515'">
				<xsl:call-template name="createNoteFrom515"/>
			</xsl:when>
			<xsl:when test="$sf06a='518'">
				<xsl:call-template name="createNoteFrom518"/>
			</xsl:when>
			<xsl:when test="$sf06a='524'">
				<xsl:call-template name="createNoteFrom524"/>
			</xsl:when>
			<xsl:when test="$sf06a='530'">
				<xsl:call-template name="createNoteFrom530"/>
			</xsl:when>
			<xsl:when test="$sf06a='533'">
				<xsl:call-template name="createNoteFrom533"/>
			</xsl:when>
			<!--
			<xsl:when test="$sf06a='534'">
				<xsl:call-template name="createNoteFrom534"/>
			</xsl:when>
-->
			<xsl:when test="$sf06a='535'">
				<xsl:call-template name="createNoteFrom535"/>
			</xsl:when>
			<xsl:when test="$sf06a='536'">
				<xsl:call-template name="createNoteFrom536"/>
			</xsl:when>
			<xsl:when test="$sf06a='538'">
				<xsl:call-template name="createNoteFrom538"/>
			</xsl:when>
			<xsl:when test="$sf06a='541'">
				<xsl:call-template name="createNoteFrom541"/>
			</xsl:when>
			<xsl:when test="$sf06a='545'">
				<xsl:call-template name="createNoteFrom545"/>
			</xsl:when>
			<xsl:when test="$sf06a='546'">
				<xsl:call-template name="createNoteFrom546"/>
			</xsl:when>
			<xsl:when test="$sf06a='561'">
				<xsl:call-template name="createNoteFrom561"/>
			</xsl:when>
			<xsl:when test="$sf06a='562'">
				<xsl:call-template name="createNoteFrom562"/>
			</xsl:when>
			<xsl:when test="$sf06a='581'">
				<xsl:call-template name="createNoteFrom581"/>
			</xsl:when>
			<xsl:when test="$sf06a='583'">
				<xsl:call-template name="createNoteFrom583"/>
			</xsl:when>
			<xsl:when test="$sf06a='585'">
				<xsl:call-template name="createNoteFrom585"/>
			</xsl:when>

			<!--	note 5XX	-->

			<xsl:when test="$sf06a='501'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='507'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='513'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='514'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='516'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='522'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='525'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='526'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='544'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='552'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='555'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='556'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='565'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='567'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='580'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='584'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>
			<xsl:when test="$sf06a='586'">
				<xsl:call-template name="createNoteFrom5XX"/>
			</xsl:when>

			<!--  subject 034 043 045 255 656 662 752 	-->

			<xsl:when test="$sf06a='034'">
				<xsl:call-template name="createSubGeoFrom034"/>
			</xsl:when>
			<xsl:when test="$sf06a='043'">
				<xsl:call-template name="createSubGeoFrom043"/>
			</xsl:when>
			<xsl:when test="$sf06a='045'">
				<xsl:call-template name="createSubTemFrom045"/>
			</xsl:when>
			<xsl:when test="$sf06a='255'">
				<xsl:call-template name="createSubGeoFrom255"/>
			</xsl:when>

			<xsl:when test="$sf06a='600'">
				<xsl:call-template name="createSubNameFrom600"/>
			</xsl:when>
			<xsl:when test="$sf06a='610'">
				<xsl:call-template name="createSubNameFrom610"/>
			</xsl:when>
			<xsl:when test="$sf06a='611'">
				<xsl:call-template name="createSubNameFrom611"/>
			</xsl:when>

			<xsl:when test="$sf06a='630'">
				<xsl:call-template name="createSubTitleFrom630"/>
			</xsl:when>

			<xsl:when test="$sf06a='648'">
				<xsl:call-template name="createSubChronFrom648"/>
			</xsl:when>
			<xsl:when test="$sf06a='650'">
				<xsl:call-template name="createSubTopFrom650"/>
			</xsl:when>
			<xsl:when test="$sf06a='651'">
				<xsl:call-template name="createSubGeoFrom651"/>
			</xsl:when>


			<xsl:when test="$sf06a='653'">
				<xsl:call-template name="createSubFrom653"/>
			</xsl:when>
			<xsl:when test="$sf06a='656'">
				<xsl:call-template name="createSubFrom656"/>
			</xsl:when>
			<xsl:when test="$sf06a='662'">
				<xsl:call-template name="createSubGeoFrom662752"/>
			</xsl:when>
			<xsl:when test="$sf06a='752'">
				<xsl:call-template name="createSubGeoFrom662752"/>
			</xsl:when>

			<!--  location  852 856 -->

			<xsl:when test="$sf06a='852'">
				<xsl:call-template name="createLocationFrom852"/>
			</xsl:when>
			<xsl:when test="$sf06a='856'">
				<xsl:call-template name="createLocationFrom856"/>
			</xsl:when>

			<xsl:when test="$sf06a='490'">
				<xsl:call-template name="createRelatedItemFrom490"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- titleInfo 130 730 245 246 240 740 210 -->

	<!-- 130 tmee 1.101 20140806-->
	<xsl:template name="createTitleInfoFrom130">

			<titleInfo type="uniform">
				<title>
					<xsl:variable name="str">
						<xsl:for-each select="marc:subfield">
							<xsl:if test="(contains('s',@code))">
								<xsl:value-of select="text()"/>
								<xsl:text> </xsl:text>
							</xsl:if>
							<xsl:if test="(contains('adfklmors',@code) and (not(../marc:subfield[@code='n' or @code='p']) or (following-sibling::marc:subfield[@code='n' or @code='p'])))">
								<xsl:value-of select="text()"/>
								<xsl:text> </xsl:text>
							</xsl:if>
						</xsl:for-each>
					</xsl:variable>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="part"/>
			</titleInfo>
		
	</xsl:template>
	<xsl:template name="createTitleInfoFrom730">
		<titleInfo type="uniform">
			<title>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield">
						<xsl:if test="(contains('s',@code))">
							<xsl:value-of select="text()"/>
							<xsl:text> </xsl:text>
						</xsl:if>
						<xsl:if test="(contains('adfklmors',@code) and (not(../marc:subfield[@code='n' or @code='p']) or (following-sibling::marc:subfield[@code='n' or @code='p'])))">
							<xsl:value-of select="text()"/>
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
					</xsl:with-param>
				</xsl:call-template>
			</title>
			<xsl:call-template name="part"/>
		</titleInfo>
	</xsl:template>

	<xsl:template name="createTitleInfoFrom210">
		<titleInfo type="abbreviated">
			<xsl:if test="marc:datafield[@tag='210'][@ind2='2']">
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code='2']"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="xxx880"/>
			<title>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">a</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</title>
			<xsl:call-template name="subtitle"/>
		</titleInfo>
	</xsl:template>
	<!-- 1.79 -->
	<xsl:template name="createTitleInfoFrom245">
		<titleInfo>
			<xsl:call-template name="xxx880"/>
			<xsl:variable name="title">
				<xsl:choose>
					<xsl:when test="marc:subfield[@code='b']">
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="axis">b</xsl:with-param>
							<xsl:with-param name="beforeCodes">afgks</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">abfgks</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="titleChop">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="$title"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="@ind2&gt;0">
					<xsl:if test="@tag!='880'">
						<nonSort>
							<xsl:value-of select="substring($titleChop,1,@ind2)"/>
						</nonSort>
					</xsl:if>
					<title>
						<xsl:value-of select="substring($titleChop,@ind2+1)"/>
					</title>
				</xsl:when>
				<xsl:otherwise>
					<title>
						<xsl:value-of select="$titleChop"/>
					</title>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="marc:subfield[@code='b']">
				<subTitle>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="specialSubfieldSelect">
								<xsl:with-param name="axis">b</xsl:with-param>
								<xsl:with-param name="anyCodes">b</xsl:with-param>
								<xsl:with-param name="afterCodes">afgks</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</subTitle>
			</xsl:if>
			<xsl:call-template name="part"/>
		</titleInfo>
	</xsl:template>

	<xsl:template name="createTitleInfoFrom246">
		<titleInfo type="alternative">
			<xsl:call-template name="xxx880"/>
			<xsl:for-each select="marc:subfield[@code='i']">
				<xsl:attribute name="displayLabel">
					<xsl:value-of select="text()"/>
				</xsl:attribute>
			</xsl:for-each>
			<title>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<!-- 1/04 removed $h, $b -->
							<xsl:with-param name="codes">af</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</title>
			<xsl:call-template name="subtitle"/>
			<xsl:call-template name="part"/>
		</titleInfo>
	</xsl:template>

	<!-- 240 nameTitleGroup-->
	<!-- 1.102 -->

	<xsl:template name="createTitleInfoFrom240">
		<titleInfo type="uniform">
			<xsl:if test="//marc:datafield[@tag='100']|//marc:datafield[@tag='110']|//marc:datafield[@tag='111']">
				<xsl:attribute name="nameTitleGroup">
					<xsl:text>1</xsl:text>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="xxx880"/>
			<title>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield">
						<xsl:if test="(contains('adfklmors',@code) and (not(../marc:subfield[@code='n' or @code='p']) or (following-sibling::marc:subfield[@code='n' or @code='p'])))">
							<xsl:value-of select="text()"/>
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
					</xsl:with-param>
				</xsl:call-template>
			</title>
			<xsl:call-template name="part"/>
		</titleInfo>
	</xsl:template>

	<xsl:template name="createTitleInfoFrom740">
		<titleInfo type="alternative">
			<xsl:call-template name="xxx880"/>
			<title>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">ah</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</title>
			<xsl:call-template name="part"/>
		</titleInfo>
	</xsl:template>

	<!-- name 100 110 111 1.93      -->

	<xsl:template name="createNameFrom100">
		<xsl:if test="@ind1='0' or @ind1='1'">
			<name type="personal">
				<xsl:attribute name="usage">
					<xsl:text>primary</xsl:text>
				</xsl:attribute>
				<xsl:call-template name="xxx880"/>
				<xsl:if test="//marc:datafield[@tag='240']">
					<xsl:attribute name="nameTitleGroup">
						<xsl:text>1</xsl:text>
					</xsl:attribute>
				</xsl:if>
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:if>
		<!-- 1.99 240 fix 20140804 -->
		<xsl:if test="@ind1='3'">
			<name type="family">
				<xsl:attribute name="usage">
					<xsl:text>primary</xsl:text>
				</xsl:attribute>
				<xsl:call-template name="xxx880"/>
			
				<xsl:if test="ancestor::marcrecord//marc:datafield[@tag='240']">
					<xsl:attribute name="nameTitleGroup">
						<xsl:text>1</xsl:text>
					</xsl:attribute>
				</xsl:if>
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:if>
	</xsl:template>

	<xsl:template name="createNameFrom110">
		<name type="corporate">
			<xsl:call-template name="xxx880"/>
			<xsl:if test="//marc:datafield[@tag='240']">
				<xsl:attribute name="nameTitleGroup">
					<xsl:text>1</xsl:text>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="nameABCDN"/>
			<xsl:call-template name="role"/>
		</name>
	</xsl:template>


	<!-- 111 1.104 20141104 -->

	<xsl:template name="createNameFrom111">
		<name type="conference">
			<xsl:call-template name="xxx880"/>
			<xsl:if test="//marc:datafield[@tag='240']">
				<xsl:attribute name="nameTitleGroup">
					<xsl:text>1</xsl:text>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="nameACDENQ"/>
			<xsl:call-template name="role"/>
		</name>
	</xsl:template>



	<!-- name 700 710 711 720 -->

	<xsl:template name="createNameFrom700">
		<xsl:if test="@ind1='1'">
			<name type="personal">
				<xsl:call-template name="xxx880"/>
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:if>
		<xsl:if test="@ind1='3'">
			<name type="family">
				<xsl:call-template name="xxx880"/>
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:if>
	</xsl:template>

	<xsl:template name="createNameFrom710">
		<name type="corporate">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="nameABCDN"/>
			<xsl:call-template name="role"/>
		</name>
	</xsl:template>

<!-- 111 1.104 20141104 -->
	<xsl:template name="createNameFrom711">
		<name type="conference">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="nameACDENQ"/>
			<xsl:call-template name="role"/>
		</name>
	</xsl:template>
	
	
	<xsl:template name="createNameFrom720">
		<!-- 1.91 FLVC correction: the original if test will fail because of xpath: the current node (from the for-each above) is already the 720 datafield -->
		<!-- <xsl:if test="marc:datafield[@tag='720'][not(marc:subfield[@code='t'])]"> -->
		<xsl:if test="not(marc:subfield[@code='t'])">
			<name>
				<xsl:if test="@ind1=1">
					<xsl:attribute name="type">
						<xsl:text>personal</xsl:text>
					</xsl:attribute>
				</xsl:if>
				<namePart>
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</namePart>
				<xsl:call-template name="role"/>
			</name>
		</xsl:if>
	</xsl:template>
	
	
	
	<!-- replced by above 1.91
	<xsl:template name="createNameFrom720">
		<xsl:if test="marc:datafield[@tag='720'][not(marc:subfield[@code='t'])]">
			<name>
				<xsl:if test="@ind1=1">
					<xsl:attribute name="type">
						<xsl:text>personal</xsl:text>
					</xsl:attribute>
				</xsl:if>
				<namePart>
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</namePart>
				<xsl:call-template name="role"/>
			</name>
		</xsl:if>
	</xsl:template>
	-->


	<!-- genre 047 336 655	-->

	<xsl:template name="createGenreFrom047">
		<genre authority="marcgt">
			<xsl:attribute name="authority">
				<xsl:value-of select="marc:subfield[@code='2']"/>
			</xsl:attribute>
			<!-- Template checks for altRepGroup - 880 $6 -->
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">abcdef</xsl:with-param>
				<xsl:with-param name="delimeter">-</xsl:with-param>
			</xsl:call-template>
		</genre>
	</xsl:template>

	<xsl:template name="createGenreFrom336">
		<genre>
			<xsl:attribute name="authority">
				<xsl:value-of select="marc:subfield[@code='2']"/>
			</xsl:attribute>
			<!-- Template checks for altRepGroup - 880 $6 -->
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">a</xsl:with-param>
				<xsl:with-param name="delimeter">-</xsl:with-param>
			</xsl:call-template>
		</genre>

	</xsl:template>

	<xsl:template name="createGenreFrom655">
		<genre authority="marcgt">
			<xsl:attribute name="authority">
				<xsl:value-of select="marc:subfield[@code='2']"/>
			</xsl:attribute>
			<!-- Template checks for altRepGroup - 880 $6 -->
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">abvxyz</xsl:with-param>
				<xsl:with-param name="delimeter">-</xsl:with-param>
			</xsl:call-template>
		</genre>
	</xsl:template>

	<!-- tOC 505 -->

	<xsl:template name="createTOCFrom505">
		<tableOfContents>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">agrt</xsl:with-param>
			</xsl:call-template>
		</tableOfContents>
	</xsl:template>

	<!-- abstract 520 -->

	<xsl:template name="createAbstractFrom520">
		<abstract>
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="@ind1=' '">Summary</xsl:when>
					<xsl:when test="@ind1='0'">Subject</xsl:when>
					<xsl:when test="@ind1='1'">Review</xsl:when>
					<xsl:when test="@ind1='2'">Scope and content</xsl:when>
					<xsl:when test="@ind1='3'">Abstract</xsl:when>
					<xsl:when test="@ind1='4'">Content advice</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">ab</xsl:with-param>
			</xsl:call-template>

		</abstract>
	</xsl:template>

	<!-- targetAudience 521 -->

	<xsl:template name="createTargetAudienceFrom521">
		<targetAudience>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">ab</xsl:with-param>
			</xsl:call-template>
		</targetAudience>
	</xsl:template>

	<!-- note 245c thru 585 -->


	<!-- 1.100 245c 20140804 -->
	<xsl:template name="createNoteFrom245c">
		<xsl:if test="marc:subfield[@code='c']">
				<note type="statement of responsibility">
					<xsl:attribute name="altRepGroup">
						<xsl:text>00</xsl:text>
					</xsl:attribute>
					<xsl:call-template name="scriptCode"/>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">c</xsl:with-param>
					</xsl:call-template>
				</note>
		</xsl:if>

	</xsl:template>

	<xsl:template name="createNoteFrom362">
		<note type="date/sequential designation">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom500">
		<note>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:value-of select="marc:subfield[@code='a']"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom502">
		<note type="thesis">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom504">
		<note type="bibliography">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom508">
		<note type="creation/production credits">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='u' and @code!='3' and @code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom511">
		<note type="performers">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom515">
		<note type="numbering">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom518">
		<note type="venue">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='3' and @code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom524">
		<note type="preferred citation">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom530">
		<note type="additional physical form">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='u' and @code!='3' and @code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom533">
		<note type="reproduction">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<!-- tmee
	<xsl:template name="createNoteFrom534">
		<note type="original version">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>
-->

	<xsl:template name="createNoteFrom535">
		<note type="original location">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom536">
		<note type="funding">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom538">
		<note type="system details">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom541">
		<note type="acquisition">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom545">
		<note type="biographical/historical">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom546">
		<note type="language">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom561">
		<note type="ownership">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom562">
		<note type="version identification">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom581">
		<note type="publications">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom583">
		<note type="action">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom585">
		<note type="exhibitions">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<xsl:template name="createNoteFrom5XX">
		<note>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="uri"/>
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield[@code!='6' and @code!='8']">
					<xsl:value-of select="."/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
		</note>
	</xsl:template>

	<!-- subject Geo 034 043 045 255 656 662 752 -->

	<xsl:template name="createSubGeoFrom034">
		<xsl:if test="marc:datafield[@tag=034][marc:subfield[@code='d' or @code='e' or @code='f' or @code='g']]">
			<subject>
				<xsl:call-template name="xxx880"/>
				<cartographics>
					<coordinates>
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">defg</xsl:with-param>
						</xsl:call-template>
					</coordinates>
				</cartographics>
			</subject>
		</xsl:if>
	</xsl:template>

	<xsl:template name="createSubGeoFrom043">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c']">
				<geographicCode>
					<xsl:attribute name="authority">
						<xsl:if test="@code='a'">
							<xsl:text>marcgac</xsl:text>
						</xsl:if>
						<xsl:if test="@code='b'">
							<xsl:value-of select="following-sibling::marc:subfield[@code=2]"/>
						</xsl:if>
						<xsl:if test="@code='c'">
							<xsl:text>iso3166</xsl:text>
						</xsl:if>
					</xsl:attribute>
					<xsl:value-of select="self::marc:subfield"/>
				</geographicCode>
			</xsl:for-each>
		</subject>
	</xsl:template>

	<xsl:template name="createSubGeoFrom255">
		<subject>
			<xsl:call-template name="xxx880"/>
			<cartographics>
			<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c']">
					<xsl:if test="@code='a'">
						<scale>
							<xsl:value-of select="."/>
						</scale>
					</xsl:if>
					<xsl:if test="@code='b'">
						<projection>
							<xsl:value-of select="."/>
						</projection>
					</xsl:if>
					<xsl:if test="@code='c'">
						<coordinates>
							<xsl:value-of select="."/>
						</coordinates>
					</xsl:if>
			</xsl:for-each>
			</cartographics>
		</subject>
	</xsl:template>

	<xsl:template name="createSubNameFrom600">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subjectAuthority"/>
			<name type="personal">
				<xsl:call-template name="termsOfAddress"/>
				<namePart>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">aq</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</namePart>
				<xsl:call-template name="nameDate"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
			<xsl:if test="marc:subfield[@code='t']">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">t</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
			</xsl:if>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubNameFrom610">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subjectAuthority"/>
			<name type="corporate">
				<xsl:for-each select="marc:subfield[@code='a']">
					<namePart>
						<xsl:value-of select="."/>
					</namePart>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='b']">
					<namePart>
						<xsl:value-of select="."/>
					</namePart>
				</xsl:for-each>
				<xsl:if test="marc:subfield[@code='c' or @code='d' or @code='n' or @code='p']">
					<namePart>
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">cdnp</xsl:with-param>
						</xsl:call-template>
					</namePart>
				</xsl:if>
				<xsl:call-template name="role"/>
			</name>
			<xsl:if test="marc:subfield[@code='t']">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">t</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
			</xsl:if>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubNameFrom611">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subjectAuthority"/>
			<name type="conference">
				<namePart>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abcdeqnp</xsl:with-param>
					</xsl:call-template>
				</namePart>
				<xsl:for-each select="marc:subfield[@code='4']">
					<role>
						<roleTerm authority="marcrelator" type="code">
							<xsl:value-of select="."/>
						</roleTerm>
					</role>
				</xsl:for-each>
			</name>
			<xsl:if test="marc:subfield[@code='t']">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">tpn</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
			</xsl:if>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubTitleFrom630">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subjectAuthority"/>
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">adfhklor</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="part"/>
			</titleInfo>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubChronFrom648">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:if test="marc:subfield[@code=2]">
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code=2]"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="uri"/>
			<xsl:call-template name="subjectAuthority"/>
			<temporal>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">abcd</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</temporal>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubTopFrom650">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subjectAuthority"/>
			<topic>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">abcd</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</topic>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubGeoFrom651">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subjectAuthority"/>
			<xsl:for-each select="marc:subfield[@code='a']">
				<geographic>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString" select="."/>
					</xsl:call-template>
				</geographic>
			</xsl:for-each>
			<xsl:call-template name="subjectAnyOrder"/>
		</subject>
	</xsl:template>

	<xsl:template name="createSubFrom653">

		<xsl:if test="@ind2=' '">
			<subject>
				<topic>
					<xsl:value-of select="."/>
				</topic>
			</subject>
		</xsl:if>
		<xsl:if test="@ind2='0'">
			<subject>
				<topic>
					<xsl:value-of select="."/>
				</topic>
			</subject>
		</xsl:if>
<!-- tmee 1.93 20140130 -->
		<xsl:if test="@ind=' ' or @ind1='0' or @ind1='1'">
			<subject>
				<name type="personal">
					<namePart>
						<xsl:value-of select="."/>
					</namePart>
				</name>
			</subject>
		</xsl:if>
		<xsl:if test="@ind1='3'">
			<subject>
				<name type="family">
					<namePart>
						<xsl:value-of select="."/>
					</namePart>
				</name>
			</subject>
		</xsl:if>
		<xsl:if test="@ind2='2'">
			<subject>
				<name type="corporate">
					<namePart>
						<xsl:value-of select="."/>
					</namePart>
				</name>
			</subject>
		</xsl:if>
		<xsl:if test="@ind2='3'">
			<subject>
				<name type="conference">
					<namePart>
						<xsl:value-of select="."/>
					</namePart>
				</name>
			</subject>
		</xsl:if>
		<xsl:if test="@ind2=4">
			<subject>
				<temporal>
					<xsl:value-of select="."/>
				</temporal>
			</subject>
		</xsl:if>
		<xsl:if test="@ind2=5">
			<subject>
				<geographic>
					<xsl:value-of select="."/>
				</geographic>
			</subject>
		</xsl:if>

		<xsl:if test="@ind2=6">
			<subject>
				<genre>
					<xsl:value-of select="."/>
				</genre>
			</subject>
		</xsl:if>
	</xsl:template>

	<xsl:template name="createSubFrom656">
		<subject>
			<xsl:call-template name="xxx880"/>
			<xsl:if test="marc:subfield[@code=2]">
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code=2]"/>
				</xsl:attribute>
			</xsl:if>
			<occupation>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</xsl:with-param>
				</xsl:call-template>
			</occupation>
		</subject>
	</xsl:template>

	<xsl:template name="createSubGeoFrom662752">
		<subject>
			<xsl:call-template name="xxx880"/>
			<hierarchicalGeographic>
				<xsl:for-each select="marc:subfield[@code='a']">
					<country>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</country>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='b']">
					<state>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</state>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='c']">
					<county>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</county>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='d']">
					<city>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</city>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='e']">
					<citySection>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</citySection>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='g']">
					<area>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</area>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='h']">
					<extraterrestrialArea>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString" select="."/>
						</xsl:call-template>
					</extraterrestrialArea>
				</xsl:for-each>
			</hierarchicalGeographic>
		</subject>
	</xsl:template>

	<xsl:template name="createSubTemFrom045">
		<xsl:if test="//marc:datafield[@tag=045 and @ind1='2'][marc:subfield[@code='b' or @code='c']]">
			<subject>
				<xsl:call-template name="xxx880"/>
				<temporal encoding="iso8601" point="start">
					<xsl:call-template name="dates045b">
						<xsl:with-param name="str" select="marc:subfield[@code='b' or @code='c'][1]"/>
					</xsl:call-template>
				</temporal>
				<temporal encoding="iso8601" point="end">
					<xsl:call-template name="dates045b">
						<xsl:with-param name="str" select="marc:subfield[@code='b' or @code='c'][2]"/>
					</xsl:call-template>
				</temporal>
			</subject>
		</xsl:if>
	</xsl:template>

	<!-- classification 050 060 080 082 084 086 -->

	<xsl:template name="createClassificationFrom050">
		<xsl:for-each select="marc:subfield[@code='b']">
			<classification authority="lcc">
				<xsl:call-template name="xxx880"/>
				<xsl:if test="../marc:subfield[@code='3']">
					<xsl:attribute name="displayLabel">
						<xsl:value-of select="../marc:subfield[@code='3']"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="preceding-sibling::marc:subfield[@code='a'][1]"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="text()"/>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='a'][not(following-sibling::marc:subfield[@code='b'])]">
			<classification authority="lcc">
				<xsl:call-template name="xxx880"/>
				<xsl:if test="../marc:subfield[@code='3']">
					<xsl:attribute name="displayLabel">
						<xsl:value-of select="../marc:subfield[@code='3']"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="text()"/>
			</classification>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="createClassificationFrom060">
		<classification authority="nlm">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">ab</xsl:with-param>
			</xsl:call-template>
		</classification>
	</xsl:template>
	<xsl:template name="createClassificationFrom080">
		<classification authority="udc">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">abx</xsl:with-param>
			</xsl:call-template>
		</classification>
	</xsl:template>
	<xsl:template name="createClassificationFrom082">
		<classification authority="ddc">
			<xsl:call-template name="xxx880"/>
			<xsl:if test="marc:subfield[@code='2']">
				<xsl:attribute name="edition">
					<xsl:value-of select="marc:subfield[@code='2']"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">ab</xsl:with-param>
			</xsl:call-template>
		</classification>
	</xsl:template>
	<xsl:template name="createClassificationFrom084">
		<classification>
			<xsl:attribute name="authority">
				<xsl:value-of select="marc:subfield[@code='2']"/>
			</xsl:attribute>
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">ab</xsl:with-param>
			</xsl:call-template>
		</classification>
	</xsl:template>
	<xsl:template name="createClassificationFrom086">
		<xsl:for-each select="marc:datafield[@tag=086][@ind1=0]">
			<classification authority="sudocs">
				<xsl:call-template name="xxx880"/>
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=086][@ind1=1]">
			<classification authority="candoc">
				<xsl:call-template name="xxx880"/>
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=086][@ind1!=1 and @ind1!=0]">
			<classification>
				<xsl:call-template name="xxx880"/>
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code='2']"/>
				</xsl:attribute>
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</classification>
		</xsl:for-each>
	</xsl:template>

	<!-- identifier 020 024 022 028 010 037 UNDO Nov 23 2010 RG SM-->

	<!-- createRelatedItemFrom490 <xsl:for-each select="marc:datafield[@tag=490][@ind1=0]"> -->

	<xsl:template name="createRelatedItemFrom490">
		<relatedItem type="series">
			<xsl:call-template name="xxx880"/>
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">av</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="part"/>
			</titleInfo>
		</relatedItem>
	</xsl:template>


	<!-- location 852 856 -->

	<xsl:template name="createLocationFrom852">
		<location>
			<xsl:if test="marc:subfield[@code='a' or @code='b' or @code='e']">
				<physicalLocation>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abe</xsl:with-param>
					</xsl:call-template>
				</physicalLocation>
			</xsl:if>
			<xsl:if test="marc:subfield[@code='u']">
				<physicalLocation>
					<xsl:call-template name="uri"/>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">u</xsl:with-param>
					</xsl:call-template>
				</physicalLocation>
			</xsl:if>
			<!-- 1.78 -->
			<xsl:if test="marc:subfield[@code='h' or @code='i' or @code='j' or @code='k' or @code='l' or @code='m' or @code='t']">
				<shelfLocator>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">hijklmt</xsl:with-param>
					</xsl:call-template>
				</shelfLocator>
			</xsl:if>
		</location>
	</xsl:template>

	<xsl:template name="createLocationFrom856">
		<xsl:if test="//marc:datafield[@tag=856][@ind2!=2][marc:subfield[@code='u']]">
			<location>
				<url displayLabel="electronic resource">
					<!-- 1.41 tmee AQ1.9 added choice protocol for @usage="primary display" -->
					<xsl:variable name="primary">
						<xsl:choose>
							<xsl:when test="@ind2=0 and count(preceding-sibling::marc:datafield[@tag=856] [@ind2=0])=0">true</xsl:when>

							<xsl:when test="@ind2=1 and         count(ancestor::marc:record//marc:datafield[@tag=856][@ind2=0])=0 and         count(preceding-sibling::marc:datafield[@tag=856][@ind2=1])=0">true</xsl:when>

							<xsl:when test="@ind2!=1 and @ind2!=0 and         @ind2!=2 and count(ancestor::marc:record//marc:datafield[@tag=856 and         @ind2=0])=0 and count(ancestor::marc:record//marc:datafield[@tag=856 and         @ind2=1])=0 and         count(preceding-sibling::marc:datafield[@tag=856][@ind2])=0">true</xsl:when>
							<xsl:otherwise>false</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$primary='true'">
						<xsl:attribute name="usage">primary display</xsl:attribute>
					</xsl:if>

					<xsl:if test="marc:subfield[@code='y' or @code='3']">
						<xsl:attribute name="displayLabel">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">y3</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:if test="marc:subfield[@code='z']">
						<xsl:attribute name="note">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">z</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="marc:subfield[@code='u']"/>
				</url>
			</location>
		</xsl:if>
	</xsl:template>

	<!-- accessCondition 506 540 1.87 20130829-->

	<xsl:template name="createAccessConditionFrom506">
		<accessCondition type="restriction on access">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">abcd35</xsl:with-param>
			</xsl:call-template>
		</accessCondition>
	</xsl:template>

	<xsl:template name="createAccessConditionFrom540">
		<accessCondition type="use and reproduction">
			<xsl:call-template name="xxx880"/>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">abcde35</xsl:with-param>
			</xsl:call-template>
		</accessCondition>
	</xsl:template>

	<!-- recordInfo 040 005 001 003 -->

	<!-- 880 global copy template -->
	<xsl:template match="* | @*" mode="global_copy">
		<xsl:copy>
			<xsl:apply-templates select="* | @* | text()" mode="global_copy"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>