
<%@ page import="user.UserEJB" %>
<%@ page import="affichage.PageConsulte" %>
<%@ page import="ferme.poulet.Poulet" %>

<% try{
    UserEJB u = (UserEJB)session.getValue("u");
    String lien = (String) session.getValue("lien");

    Poulet o = new Poulet();
    o.setNomTable("POULET");
    PageConsulte pc = new PageConsulte(o, request, u);
    pc.setTitre("Fiche du poulet");
    String id = pc.getBase().getTuppleID();

    pc.getChampByName("id").setLibelle("Id");
    pc.getChampByName("nom").setLibelle("Nom");
    pc.getChampByName("race").setLibelle("Race");

    String[] ordre = {"id", "nom", "race"};
    pc.setOrdre(ordre);

    String pageRetour = "ferme/poulet/poulet-liste.jsp";
    String pageActuel = "ferme/poulet/poulet-fiche.jsp";
    String pageModif = "ferme/poulet/poulet-saisie.jsp&acte=update";
    String pageApresDelete = "ferme/poulet/poulet-liste.jsp";
    String classe = "ferme.poulet.Poulet";
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
                        <a class="btn btn-secondary pull-right" href="<%= lien + "?but="+ pageModif +"&id=" + id %>" style="margin-right: 10px">Modifier</a>
                        <a class="btn btn-danger pull-left" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=delete&bute="+pageApresDelete+"&classe="+classe %>">Supprimer</a>
                    </div>
                    <br/>
                </div>
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