class RolePriviledgeController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @privilege_pages, @privileges = paginate :privileges, :per_page => 10
  end

  def show
    @privilege = Privilege.find(params[:id])
  end

  def new
    @privilege = Privilege.new
  end

  def create
    @privilege = Privilege.new(params[:privilege])
    if @privilege.save
      flash[:notice] = 'Privilege was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @privilege = Privilege.find(params[:id])
  end

  def update
    @privilege = Privilege.find(params[:id])
    if @privilege.update_attributes(params[:privilege])
      flash[:notice] = 'Privilege was successfully updated.'
      redirect_to :action => 'show', :id => @privilege
    else
      render :action => 'edit'
    end
  end

  def destroy
    Privilege.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
