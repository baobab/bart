class RoleprivilegeController < ApplicationController
 
  def create 
   if request.post?
     @role=Role.find_by_role(params[:role][:role])
     @privilege=Privilege.find_by_privilege(params[:privilege][:privilege])
     @roleprivilege=RolePrivilege.new
     @roleprivilege.role_id=@role.role_id
     @roleprivilege.privilege_id=@privilege.privilege_id
     if @roleprivilege.save
       flash[:notice]="Role Privilege Added"
     end  
   end
 end 
 
 def list
  @role_privileges = RolePrivilege.find(:all)
  end
 
 def edit
  #return render_text params[:id]
  @role_privileges = RolePrivilege.find(params[:id]) 
 end 
 
 def update
   if request.post?
     @role=Role.find_by_role(params[:role][:role])
     @privilege=Privilege.find_by_privilege(params[:privilege][:privilege])
     @roleprivilege=RolePrivilege.new
     @roleprivilege.role_id=@role.role_id
     @roleprivilege.privilege_id=@privilege.privilege_id
     
     if @roleprivilege.update
       flash[:notice]="Role Privilege Updated"
     end  
   end

 end
 
 def show
  @role_privileges = RolePrivilege.find(params[:id])
 end 
 
 def new
  @role_privileges = RolePrivilege.new
 end 
end
