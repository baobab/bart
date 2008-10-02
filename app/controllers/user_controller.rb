class UserController < ApplicationController

  def login
    @ask_location = session[:location].nil?
    #check if request has data
    if request.get?
      session[:user_id]=nil
    else
      @user=User.new(params[:user])
      logged_in_user=@user.try_to_login      
      if logged_in_user
        if params[:location] 
          params[:location].gsub!('$','')
          valid_rooms = GlobalProperty.find_by_property("valid_rooms").property_value rescue ""
          flash[:error]="invalid room code" and return unless valid_rooms.split(",").include?(params[:location])
          session[:location] = params[:location]
        end
        location = session[:location]
        reset_session
        session[:location] = location
        session[:user_id] = logged_in_user.user_id
        session[:ip_address] = request.env['REMOTE_ADDR'] 

        #Notifier::deliver_signup_thanks
        #Notifier::deliver_daily_report
        
        show_activites_property =  GlobalProperty.find_by_property("show_activities_after_login")
        tasks = room_tasks(location)
        if tasks and tasks.length == 1
          show_activites_property = false
          logged_in_user.activities = tasks
        end

        if show_activites_property and show_activites_property.property_value == "true"
          redirect_to(:action => "activities") 
        else 
          redirect_to(:controller => "patient", :action => "menu")
        end
      else
        flash[:error]="Invalid Username or Password"
      end      
    end
    @loc_name = session[:location]
  end          
  
  
 def health_centres
     redirect_to(:controller => "patient", :action => "menu")
     @health_centres = Location.find(:all,  :order => "name").map{|r|[r.name, r.location_id]}
 end 
 
 def list_clinicians
 	@clinician_role = Role.find_by_role("clinician").id
 	@clinicians = UserRole.find_all_by_role_id(@clinician_role)
 end
  
  def logout
   #if time is 4 o'oclock then send report on logout. 
    location = session[:location]
#    reset_session
    session[:location] = location
    redirect_to(:action => "login")
  end

  def signup
    render_text "Please sign up"
  end

  def remind_password
  end

  def try_to_log_in
    User.login(self.name, self.password)
  end

  def index
    @user=User.find(session[:user_id])
    @firstname=@user.first_name
    @secondName=@user.last_name
       
    list
    return render(:action => 'list')
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#  verify :method => :post, :only => [ :destroy, :create, :update ],
        # :redirect_to => { :action => :list }
        
  def voided_list
      session[:voided_list] = false 
    @user_pages, @users = paginate(:users, :per_page => 50,:conditions =>["voided=?",true])
      render :view => 'list'
  end
  
  def list
    session[:voided_list] = true
    @user_pages, @users = paginate(:users, :per_page => 50,:conditions =>["voided=?",false])
 end

  def show
    unless session[:user_edit].nil?
     @user = User.find(session[:user_edit])
    else
     @user = User.find(:all).last
     session[:user_edit]=@user.user_id
    end  
  end

  def new
    @user = User.new
  end

  def create
       session[:user_edit] = nil
       @user = User.new(params[:user])

    if (params[:user][:password] != params[:user_confirm][:password])
      flash[:notice] = 'Password Mismatch'
    #  flash[:notice] = nil
       @user_first_name = params[:user][:first_name]
       @user_middle_name = params[:user][:middle_name]
       @user_last_name = params[:user][:last_name]
       @user_role = params[:user_role][:role_id]
       @user_admin_role = params[:user_role_admin][:role]
       @user_name = params[:user][:username]
       redirect_to :action => 'new'
      return
    end
      
    if @user.save
     # if params[:user_role_admin][:role] == "Yes"  
      #  @roles = Array.new.push params[:user_role][:role_id] 
       # @roles << "superuser"
       # @roles.each{|role|
       # user_role=UserRole.new
       # user_role.role_id = Role.find_by_role(role).role_id
       # user_role.user_id=@user.user_id
       # user_role.save
      #}
      #else
        user_role=UserRole.new
        user_role.role_id = Role.find_by_role(params[:user_role][:role_id]).role_id
        user_role.user_id=@user.user_id
        user_role.save
     # end
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'show'
    else
      flash[:notice] = 'OOps! User was not created!.'
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(session[:user_edit])
  end

  def update
    @user = User.find(params[:id])
       if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
       redirect_to :action => 'show', :id => @user
    else
      flash[:notice] = "OOps! User was not updated!."
      render :action => 'edit'
    end
  end

  def destroy
   unless request.get?
   @user = User.find(session[:user_edit])
    if @user.update_attributes(:voided => true, :void_reason => params[:user][:void_reason],:voided_by => session[:user_id],:date_voided => Time.now.to_s)
      flash[:notice]='User has successfully been removed.'
      redirect_to :action => 'voided_list'
    else
      flash[:notice]='User was not successfully removed'
      redirect_to :action => 'destroy'
    end    
   end
  end
  
  def add_role
     @user = User.find(params[:id])
     unless request.get?
        user_role=UserRole.new
        user_role.role_id = Role.find_by_role(params[:user_role][:role_id]).role_id
        user_role.user_id=@user.user_id
        user_role.save
        flash[:notice] = "You have successfuly added the role of #{params[:user_role][:role_id]}"
        redirect_to :action => "show"
      else
      user_roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role.role}
      all_roles = Role.find(:all).collect{|r|r.role}
      @roles = (all_roles - user_roles)
      @show_super_user = true if UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role.role != "superuser" }
   end
  end
  
  def delete_role
    @user = User.find(params[:id])
    unless request.post?
      @roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role.role}
    else
      role_id = Role.find_by_role(params[:user_role][:role_id]).role_id
      user_role =  UserRole.find_by_role_id_and_user_id(role_id,@user.user_id)  
      user_role.destroy
      flash[:notice] = "You have successfuly removed the role of #{params[:user_role][:role_id]}"
      redirect_to :action =>"show"
    end
  end
  
  def user_menu
    render(:layout => "layouts/menu")
  end
 
  def search_user
   session[:user_edit] = nil
   unless request.get?
     session[:user_edit] = User.find_by_username(params[:user][:username]).user_id
     redirect_to :action =>"show"
   end
  end
  
  def change_password
    @user = User.find(params[:id])
   
    unless request.get? 
      if (params[:user][:password] != params[:user_confirm][:password])
        flash[:notice] = 'Password Mismatch'
        redirect_to :action => 'new'
        return
      else
        if @user.update_attributes(params[:user])
          flash[:notice] = "Password successfully changed"
          redirect_to :action => "show"
          return
        else
          flash[:notice] = "Password change failed"  
        end    
      end
    end

  end
  
  def activities
    allowed_tasks = room_tasks(session[:location])
    
    # Don't show tasks that have been disabled
    @privileges = User.current_user.privileges.reject{|priv| GlobalProperty.find_by_property("disable_tasks").property_value.split(",").include?(priv.privilege)}
    ## For restricted locations, allowed tasks override user role privileges
    @privileges = Privilege.find(:all).select{|priv| allowed_tasks.include?(priv.privilege)} if allowed_tasks

    @activities = User.current_user.activities.reject{|activity| GlobalProperty.find_by_property("disable_tasks").property_value.split(",").include?(activity)}
  end
  
  def change_activities
    User.current_user.activities = params[:user][:activities]
    redirect_to(:controller => 'patient', :action => "menu")
  end
  
end
