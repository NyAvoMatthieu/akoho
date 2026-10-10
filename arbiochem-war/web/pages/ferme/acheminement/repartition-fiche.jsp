<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="user.UserEJB" %>
<%@ page import="affichage.PageConsulte" %>
<%@ page import="ferme.acheminement.Repartition" %>
<%@ page import="constante.ConstanteEtat" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>

<% try{
    UserEJB u = (UserEJB)session.getValue("u");
    String lien = (String) session.getValue("lien");

    Repartition o = new Repartition();
    o.setNomTable("REPARTITION");
    PageConsulte pc = new PageConsulte(o, request, u);
    pc.setTitre("Fiche de la r&eacute;partition");
    String id = pc.getBase().getTuppleID();

    pc.getChampByName("id").setLibelle("Id");
    pc.getChampByName("daty").setLibelle("Date de la r&eacute;partition");
    pc.getChampByName("idControlePoulailler").setLibelle("Contr&ocirc;le de poulailler");
    pc.getChampByName("idBL").setLibelle("Bon de livraison");
    pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
    pc.getChampByName("etat").setVisible(false);

    String[] ordre = {"id", "daty", "idControlePoulailler", "idBL", "etatlib"};
    pc.setOrdre(ordre);

    String pageActuel = "ferme/acheminement/repartition-fiche.jsp";
    String pageRetour = "ferme/acheminement/repartition-liste.jsp";
    String pageApresDelete = "ferme/acheminement/repartition-liste.jsp";
    String classe = "ferme.acheminement.Repartition";
    String pageModif = "ferme/acheminement/repartition-saisie.jsp&acte=update";

    Map<String, String> map = new HashMap<>();
    map.put("inc/repartition-details", "");
    String tab = request.getParameter("tab");
    if (tab == null) {
        tab = "inc/repartition-details";
    }
    map.put(tab, "active");
    tab = tab + ".jsp";

    o = (Repartition) pc.getBase();
%>

<div class="content-wrapper">

<h1 class="box-title"><a href=<%= lien + "?but=" + pageRetour%>> <i class="fa fa-angle-left"></i></a><%=pc.getTitre()%></h1>

<div class="row m-0">
    <div class="col-md-3"></div>
    <div class="col-md-6">
        <div class="box-fiche">
            <div class="box">
                <div class="box-body">
                    <%
                        out.println(pc.getHtml());
                    %>
                    <br/>
                    <div class="box-footer">
                        <% if (o.getEtat() < ConstanteEtat.getEtatValider()) { %>
                            <a class="btn btn-primary pull-right" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=valider&bute="+pageActuel+"&classe="+classe %>">Valider</a>
                            <a class="btn btn-secondary pull-right" href="<%= lien + "?but="+ pageModif +"&id=" + id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=delete&bute="+pageApresDelete+"&classe="+classe %>">Supprimer</a>
                        <% } %>
                    </div>
                    <br/>
                </div>
            </div>
        </div>
    </div>
</div>
<div class="row m-0">
    <div class="col-md-12 nopadding">
        <div class="nav-tabs-custom">
            <ul class="nav nav-tabs">
                <li class="<%=map.get("inc/repartition-details")%>"><a href="<%= lien %>?but=<%= pageActuel %>&id=<%= id %>&tab=inc/repartition-details">D&eacute;tails</a></li>
            </ul>
            <div class="tab-content">
                <jsp:include page="<%= tab %>" >
                    <jsp:param name="id" value="<%= id %>" />
                </jsp:include>
            </div>
        </div>
    </div>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>