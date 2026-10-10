<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageInsert"%>
<%@ page import="affichage.Liste"%>
<%@ page import="user.UserEJB" %>
<%@ page import="ferme.configuration.Compartiment" %>
<%@ page import="ferme.configuration.Batiment" %>

<% try{
    UserEJB u = (UserEJB) session.getValue("u");
    String mapping = "ferme.configuration.Compartiment";
    String nomTable = "COMPARTIMENT";
    String apres = "ferme/configuration/compartiment/compartiment-fiche.jsp";

    Compartiment o = new Compartiment();
    o.setNomTable(nomTable);
    PageInsert pi = new PageInsert(o, request, u);
    pi.setLien((String) session.getValue("lien"));
    pi.setTitre("Saisie compartiment");

    pi.getFormu().getChamp("id").setLibelle("Id");
    pi.getFormu().getChamp("nom").setLibelle("Nom");
    pi.getFormu().getChamp("capacite").setLibelle("Capacit&eacute;");
    pi.getFormu().getChamp("idPoulailler").setLibelle("Poulailler (b&acirc;timent)");

    affichage.Liste[] listef = new Liste[1];
    Batiment batiment = new Batiment();
    listef[0] = new Liste("idPoulailler", batiment, "nomBatiment", "id");
    pi.getFormu().changerEnChamp(listef);
    pi.getFormu().getChamp("idPoulailler").setLibelle("Poulailler (b&acirc;timent)");

    String[] ordre = {"nom", "capacite", "idPoulailler"};
    pi.getFormu().setOrdre(ordre);

    String acte = request.getParameter("acte");
    if (acte != null && acte.equalsIgnoreCase("update")) {
        pi.setTitre("Modification compartiment");
    }

    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
%>

<div class="content-wrapper">
    <h1><%=pi.getTitre()%></h1>
    <form action="<%=pi.getLien()%>?but=apresTarif.jsp" method="post" name="<%=nomTable%>" id="<%=nomTable%>">
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%=apres%>">
        <input name="classe" type="hidden" id="classe" value="<%=mapping%>">
        <input name="nomtable" type="hidden" id="nomtable" value="<%=nomTable%>">
    </form>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>